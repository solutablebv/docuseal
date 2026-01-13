# frozen_string_literal: true

class SendSubmitterInvitationEmailJob
  include Sidekiq::Job

  def perform(params = {})
    submitter = Submitter.find(params['submitter_id'])

    return if submitter.completed_at?
    return if submitter.submission.archived_at?
    return if submitter.template&.archived_at?
    return if submitter.submission.source == 'invite' && !Accounts.can_send_emails?(submitter.account, on_events: true)

    unless Accounts.can_send_invitation_emails?(submitter.account)
      Rollbar.warning("Skip email: #{submitter.account.id}") if defined?(Rollbar)

      return
    end

    mail = SubmitterMailer.invitation_email(submitter)

    Submitters::ValidateSending.call(submitter, mail)

    mail.deliver_now!

    SubmissionEvent.create!(submitter:, event_type: 'send_email')

    submitter.sent_at ||= Time.current
    submitter.save!

    schedule_reminders(submitter)
  end

  private

  def schedule_reminders(submitter)
    reminder_config = AccountConfig.find_by(account: submitter.account, key: AccountConfig::SUBMITTER_REMINDERS)

    return unless reminder_config&.value.present?

    durations = reminder_config.value

    [:first_duration, :second_duration, :third_duration].each_with_index do |duration_key, index|
      duration_str = durations[duration_key.to_s]
      next if duration_str.blank? || duration_str.to_s.downcase == 'none'

      parsed_duration = AccountConfigs.parse_reminder_duration(duration_str)
      next unless parsed_duration

      reminder_number = index + 1

      SendSubmitterReminderEmailJob.perform_at(
        submitter.sent_at + parsed_duration,
        'submitter_id' => submitter.id,
        'reminder_number' => reminder_number
      )
    end
  end
end
