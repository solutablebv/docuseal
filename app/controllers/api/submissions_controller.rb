# frozen_string_literal: true

module Api
  class SubmissionsController < ApiBaseController
    load_and_authorize_resource :template, only: :create
    load_and_authorize_resource :submission, only: %i[show index destroy]

    before_action only: :create do
      authorize!(:create, Submission)
    end

    before_action only: :pdf do
      authorize!(:create, Submission)
    end

    def index
      submissions = Submissions.search(current_user, @submissions, params[:q])
      submissions = filter_submissions(submissions, params)

      submissions = paginate(submissions.preload(:created_by_user, :submitters,
                                                 template: { folder: :parent_folder },
                                                 combined_document_attachment: :blob,
                                                 audit_trail_attachment: :blob))

      expires_at = Accounts.link_expires_at(current_account)

      render json: {
        data: submissions.map do |s|
          Submissions::SerializeForApi.call(s, s.submitters, params,
                                            with_events: false, with_documents: false, with_values: false, expires_at:)
        end,
        pagination: {
          count: submissions.size,
          next: submissions.last&.id,
          prev: submissions.first&.id
        }
      }
    end

    def show
      submitters = @submission.submitters.preload(documents_attachments: :blob, attachments_attachments: :blob)

      submitters.each do |submitter|
        if submitter.completed_at? && submitter.documents_attachments.blank?
          submitter.documents_attachments = Submissions::EnsureResultGenerated.call(submitter)
        end
      end

      if @submission.audit_trail_attachment.blank? && submitters.all?(&:completed_at?)
        @submission.audit_trail_attachment = Submissions::EnsureAuditGenerated.call(@submission)
      end

      render json: Submissions::SerializeForApi.call(@submission, submitters, params)
    end

    def create
      Params::SubmissionCreateValidator.call(params)

      return render json: { error: 'Template not found' }, status: :unprocessable_content if @template.nil?

      if @template.fields.blank?
        Rollbar.warning("Template does not contain fields: #{@template.id}") if defined?(Rollbar)

        return render json: { error: 'Template does not contain fields' }, status: :unprocessable_content
      end

      params[:send_email] = true unless params.key?(:send_email)
      params[:send_sms] = false unless params.key?(:send_sms)

      submissions = create_submissions(@template, params)

      WebhookUrls.enqueue_events(submissions, 'submission.created')

      Submissions.send_signature_requests(submissions)

      submissions.each do |submission|
        submission.submitters.each do |submitter|
          next unless submitter.completed_at?

          ProcessSubmitterCompletionJob.perform_async('submitter_id' => submitter.id, 'send_invitation_email' => false)
        end
      end

      SearchEntries.enqueue_reindex(submissions)

      render json: build_create_json(submissions)
    rescue Submitters::NormalizeValues::BaseError, Submissions::CreateFromSubmitters::BaseError,
           DownloadUtils::UnableToDownload => e
      Rollbar.warning(e) if defined?(Rollbar)

      render json: { error: e.message }, status: :unprocessable_content
    end

    def pdf
      Params::SubmissionPdfValidator.call(params)

      # Create temporary template
      template = create_temp_template_from_pdf

      # Create submission using existing logic
      params[:template_id] = template.id
      params[:send_email] = true unless params.key?(:send_email)
      params[:send_sms] = false unless params.key?(:send_sms)

      submissions = create_submissions(template, params)

      WebhookUrls.enqueue_events(submissions, 'submission.created')

      Submissions.send_signature_requests(submissions)

      submissions.each do |submission|
        submission.submitters.each do |submitter|
          next unless submitter.completed_at?

          ProcessSubmitterCompletionJob.perform_async('submitter_id' => submitter.id, 'send_invitation_email' => false)
        end
      end

      SearchEntries.enqueue_reindex(submissions)

      render json: build_create_json(submissions)
    rescue Params::BaseValidator::InvalidParameterError,
           Submitters::NormalizeValues::BaseError,
           Submissions::CreateFromSubmitters::BaseError,
           DownloadUtils::UnableToDownload,
           Submissions::ValidateTextTagFields::InvalidFieldError,
           StandardError => e
      Rollbar.error(e) if defined?(Rollbar)
      render json: { error: "PDF submission error: #{e.message}" }, status: :unprocessable_content
    end

    def destroy
      if params[:permanently].in?(['true', true])
        @submission.destroy!
      else
        @submission.update!(archived_at: Time.current)

        WebhookUrls.enqueue_events(@submission, 'submission.archived')
      end

      render json: @submission.as_json(only: %i[id archived_at])
    end

    private

    def filter_submissions(submissions, params)
      submissions = submissions.where(template_id: params[:template_id]) if params[:template_id].present?
      submissions = submissions.where(slug: params[:slug]) if params[:slug].present?

      if params[:template_folder].present?
        folders =
          TemplateFolders.filter_by_full_name(TemplateFolder.accessible_by(current_ability), params[:template_folder])

        submissions = submissions.joins(:template).where(template: { folder_id: folders.pluck(:id) })
      end

      if params.key?(:archived)
        submissions = params[:archived].in?(['true', true]) ? submissions.archived : submissions.active
      end

      Submissions::Filter.call(submissions, current_user, params)
    end

    def build_create_json(submissions)
      json = submissions.flat_map do |submission|
        submission.submitters.map do |s|
          Submitters::SerializeForApi.call(s, with_documents: false, with_urls: true, params:)
        end
      end

      if request.path.ends_with?('/init')
        json =
          if submissions.size == 1
            {
              id: submissions.first.id,
              submitters: json,
              expire_at: submissions.first.expire_at,
              created_at: submissions.first.created_at
            }
          else
            { submitters: json }
          end
      end

      json
    end

    def create_submissions(template, params)
      is_send_email = !params[:send_email].in?(['false', false])

      if (emails = (params[:emails] || params[:email]).presence) &&
         params[:submission].blank? && params[:submitters].blank?
        Submissions.create_from_emails(template:,
                                       user: current_user,
                                       source: :api,
                                       mark_as_sent: is_send_email,
                                       emails:,
                                       params:)
      else
        submissions_attrs, attachments =
          Submissions::NormalizeParamUtils.normalize_submissions_params!(submissions_params, template)

        submissions = Submissions.create_from_submitters(
          template:,
          user: current_user,
          source: :api,
          submitters_order: params[:submitters_order] || params[:order] || 'preserved',
          submissions_attrs:,
          params:
        )

        submitters = submissions.flat_map(&:submitters)

        Submissions::NormalizeParamUtils.save_default_value_attachments!(attachments, submitters)

        submitters.each do |submitter|
          SubmissionEvents.create_with_tracking_data(submitter, 'api_complete_form', request) if submitter.completed_at?
        end

        submissions
      end
    end

    def create_temp_template_from_pdf
      template = Template.new(
        account: current_account,
        author: current_user,
        folder: current_account.default_template_folder,
        name: params[:name] || params['name'] || 'PDF Submission',
        source: :api
      )

      Templates.maybe_assign_access(template)
      template.save!

      all_fields = []
      all_submitters = build_submitters_from_params

      # Process each document
      documents_params = params[:documents] || params['documents']
      documents_params.each_with_index do |doc_params, doc_index|
        file_param = doc_params[:file] || doc_params['file']
        pdf_data = get_pdf_data(file_param)
        filename = (doc_params[:name] || doc_params['name']) || "document-#{doc_index + 1}.pdf"

        # Extract text tags (returns 0-based page indices)
        extracted_fields = Submissions::ExtractTextTags.call(pdf_data)

        # Optionally remove text tags (must be done before converting page numbers)
        remove_tags = params[:remove_text_tags] || params['remove_text_tags']
        # Default to true if not specified (remove tags by default)
        if remove_tags != false && remove_tags != 'false' && remove_tags != 0 && remove_tags != '0'
          pdf_data = Submissions::RemoveTextTags.call(pdf_data, extracted_fields)
        end

        # Create uploaded file
        tempfile = Tempfile.new(filename)
        tempfile.binmode
        tempfile.write(pdf_data)
        tempfile.rewind

        file = ActionDispatch::Http::UploadedFile.new(
          tempfile:,
          filename:,
          type: 'application/pdf'
        )

        # Create document attachment
        documents = Templates::CreateAttachments.call(template, { files: [file] }, extract_fields: false)
        document = documents.first

        raise StandardError, 'Failed to create document attachment' if document.nil?

        # Update field areas with attachment UUID
        # Note: page numbers are kept 0-based to match view indexing and PDF array access
        extracted_fields.each do |field|
          next if field['areas'].blank?

          field['areas'].each do |area|
            area['attachment_uuid'] = document.uuid
            # Page is already 0-based from extract_text_tags, keep it as is
          end
        end

        all_fields.concat(extracted_fields) if extracted_fields.present?
      end

      # Map roles to submitter UUIDs
      fields_to_add = []
      all_fields.each do |field|
        role = field.delete('_role')
        if role.present?
          # Prioritize role over name for matching (role is more specific)
          submitter = all_submitters.find { |s| (s['role'] || s['name']).to_s.casecmp(role.to_s).zero? }
          field['submitter_uuid'] = submitter['uuid'] if submitter
        else
          # If no role specified, duplicate field for all submitters so it's visible to everyone
          if all_submitters.any?
            all_submitters.each do |submitter|
              field_copy = field.deep_dup
              field_copy['uuid'] = SecureRandom.uuid
              field_copy['submitter_uuid'] = submitter['uuid']
              fields_to_add << field_copy
            end
            # Remove original field since we've duplicated it
            field['_remove'] = true
          end
        end
      end
      # Remove fields marked for removal and add duplicated fields
      all_fields.reject! { |f| f['_remove'] }
      all_fields.concat(fields_to_add)

      # Validate fields if any were extracted
      Submissions::ValidateTextTagFields.call(all_fields, all_submitters) if all_fields.present?

      # Set template fields and submitters
      template.fields = all_fields
      template.submitters = all_submitters

      # If no fields were extracted, we still need at least empty fields array
      template.fields = [] if template.fields.blank?

      # Build schema
      template.schema = template.documents.map do |doc|
        { attachment_uuid: doc.uuid, name: doc.filename.base }
      end

      template.save!

      template
    end

    def get_pdf_data(file_param)
      file_value = file_param.to_s

      if file_value.match?(/\Ahttps?:\/\//i)
        # Download from URL
        DownloadUtils.call(file_value).body
      elsif file_value.match?(/\Adata:/)
        # Data URI
        Base64.decode64(file_value.split(',', 2).last)
      else
        # Base64 string
        Base64.decode64(file_value)
      end
    end

    def build_submitters_from_params
      submitters_params = params[:submitters] || params['submitters'] || []
      submitters_params.map do |submitter_params|
        # For JSON params, keys are strings, so check string keys first
        # Use .presence to handle empty strings
        role = (submitter_params['role'] || submitter_params[:role]).presence
        name = (submitter_params['name'] || submitter_params[:name]).presence
        email = (submitter_params['email'] || submitter_params[:email]).presence
        
        {
          'uuid' => SecureRandom.uuid,
          'name' => name,
          'email' => email,
          'role' => role
        }
      end
    end

    def submissions_params
      permitted_attrs = [
        :send_email, :send_sms, :bcc_completed, :completed_redirect_url, :reply_to, :go_to_last,
        :require_phone_2fa, :require_email_2fa, :expire_at, :name,
        {
          variables: {},
          message: %i[subject body],
          submitters: [[:send_email, :send_sms, :completed_redirect_url, :uuid, :name, :email, :role,
                        :completed, :phone, :application_key, :external_id, :reply_to, :go_to_last,
                        :require_phone_2fa, :require_email_2fa, :order, :invite_by,
                        { metadata: {}, values: {}, roles: [], readonly_fields: [], message: %i[subject body],
                          fields: [:name, :uuid, :default_value, :value, :title, :description,
                                   :readonly, :required, :validation_pattern, :invalid_message,
                                   { default_value: [], value: [], preferences: {}, validation: {} }] }]]
        }
      ]

      if params.key?(:submitters)
        params.permit(*permitted_attrs)
      else
        key = params.key?(:submission) ? :submission : :submissions

        params.permit(
          { key => [permitted_attrs] }, { key => permitted_attrs }
        ).fetch(key, [])
      end
    end
  end
end
