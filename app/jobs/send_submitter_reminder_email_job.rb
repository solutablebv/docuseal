# frozen_string_literal: true

class SendSubmitterReminderEmailJob
    include Sidekiq::Job

    def perform(params = {})
        submitter = Submitter.find(params['submitter_id'])
        reminder_number = params['reminder_number'].to_i

        return if submitter.completed_at?
        return if submitter.declined_at?
        return if submitter.submission.archived_at?
        return if submitter.template&.archived_at?
        return if submitter.submission.source == 'invite' && !Accounts.can_send_emails?(submitter.account, on_events: true)

        unless Accounts.can_send_invitation_emails?(submitter.account)
            Rollbar.warning("Skip reminder email: #{submitter.account.id}") if defined?(Rollbar)

            return
        end

        # Idempotency check: prevent duplicate reminders on retry
        existing_event = submitter.submission_events.where(
            event_type: 'send_reminder_email'
        ).find { |event| event.data.is_a?(Hash) && event.data['reminder_number'] == reminder_number }

        return if existing_event

        mail = SubmitterMailer.reminder_email(submitter, reminder_number: reminder_number)

        Submitters::ValidateSending.call(submitter, mail)

        mail.deliver_now!

        SubmissionEvent.create!(
            submitter:,
            event_type: 'send_reminder_email',
            data: { 'reminder_number' => reminder_number }
        )
    end
end

