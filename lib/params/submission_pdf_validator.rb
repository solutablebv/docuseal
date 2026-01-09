# frozen_string_literal: true

module Params
  class SubmissionPdfValidator < BaseValidator
    def call
      required(params, :documents)
      required(params, :submitters)

      type(params, :documents, Array)
      type(params, :submitters, Array)

      validate_documents
      validate_submitters
      validate_optional_params

      true
    end

    private

    def validate_documents
      raise_error('documents array cannot be empty') if params[:documents].blank?

      in_path_each(params, :documents) do |document_params|
        required(document_params, :name)
        required(document_params, :file)

        type(document_params, :name, String)
        type(document_params, :file, String)

        # Validate file is base64 or URL
        file_value = document_params[:file].to_s
        is_url = file_value.match?(/\Ahttps?:\/\//i)
        is_base64 = file_value.match?(/\Adata:/) || begin
          Base64.strict_decode64(file_value)
          true
        rescue ArgumentError
          false
        end

        unless is_url || is_base64
          raise_error('file must be a valid base64 string or URL')
        end

        # Validate optional fields array
        if document_params[:fields].present?
          type(document_params, :fields, Array)
        end

        # Validate optional position
        if document_params[:position].present?
          type(document_params, :position, Integer)
        end
      end
    end

    def validate_submitters
      raise_error('submitters array cannot be empty') if params[:submitters].blank?

      in_path_each(params, :submitters) do |submitter_params|
        required(submitter_params, :email)

        type(submitter_params, :name, String)
        type(submitter_params, :email, String)
        type(submitter_params, :role, String)
        type(submitter_params, :phone, String)
        type(submitter_params, :values, Hash)
        type(submitter_params, :metadata, Hash)
        type(submitter_params, :external_id, String)

        email_format(submitter_params, :email, message: 'email is invalid')

        if submitter_params[:phone].present?
          format(submitter_params, :phone, /\A\+\d+\z/,
               message: 'phone should start with +<country code> and contain only digits')
        end

        boolean(submitter_params, :send_email)
        boolean(submitter_params, :send_sms)
        boolean(submitter_params, :completed)
        boolean(submitter_params, :require_phone_2fa)
        boolean(submitter_params, :require_email_2fa)

        type(submitter_params, :completed_redirect_url, String)
        type(submitter_params, :reply_to, String)
        type(submitter_params, :order, Integer)
        type(submitter_params, :invite_by, String)
      end
    end

    def validate_optional_params
      type(params, :name, String)
      type(params, :completed_redirect_url, String)
      type(params, :bcc_completed, String)
      type(params, :reply_to, String)
      type(params, :expire_at, String)
      type(params, :order, String)
      type(params, :variables, Hash)
      type(params, :message, Hash)

      boolean(params, :send_email)
      boolean(params, :send_sms)
      boolean(params, :remove_text_tags)
      boolean(params, :go_to_last)
      boolean(params, :require_phone_2fa)
      boolean(params, :require_email_2fa)

      email_format(params, :bcc_completed, message: 'bcc_completed email is invalid') if params[:bcc_completed].present?
      email_format(params, :reply_to, message: 'reply_to email is invalid') if params[:reply_to].present?

      value_in(params, :order, %w[preserved random], allow_nil: true)

      if params[:message].present?
        in_path(params, :message) do |message_params|
          type(message_params, :subject, String)
          type(message_params, :body, String)
        end
      end
    end
  end
end

