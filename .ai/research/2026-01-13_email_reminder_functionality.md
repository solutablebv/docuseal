# Research Report

**Date:** 2026-01-13
**Topic:** Email Reminder Functionality - How Reminders Are Sent
**Target Path:** /home/zen-14/projects/business/docuseal

---

## Summary

This research investigated how email reminders are scheduled and sent for signature requests in the DocuSeal codebase. The investigation revealed that while the UI and configuration infrastructure for reminders exists, **the actual reminder scheduling and sending functionality appears to be missing or incomplete**. The system has:

- A configuration interface for setting reminder durations (first, second, third reminders)
- Storage for reminder configuration in `AccountConfig` with key `SUBMITTER_REMINDERS`
- Event tracking for reminder emails (`send_reminder_email` event type)
- **BUT NO CODE** that actually schedules or sends reminder emails based on the configured durations

The initial invitation email is sent via `SendSubmitterInvitationEmailJob`, but there is no code that schedules follow-up reminder emails based on the `first_duration`, `second_duration`, and `third_duration` configuration values.

---

## Codebase/Documentation Index

```
app/
├── controllers/
│   ├── notifications_settings_controller.rb      # Handles reminder config UI
│   └── submission_events_controller.rb           # Tracks reminder events
├── jobs/
│   └── send_submitter_invitation_email_job.rb   # Sends initial invitation (NOT reminders)
├── mailers/
│   └── submitter_mailer.rb                      # Email templates (no reminder_email method found)
├── models/
│   ├── account_config.rb                        # Stores reminder config (SUBMITTER_REMINDERS)
│   └── submission_event.rb                       # Tracks events including send_reminder_email
└── views/
    └── notifications_settings/
        ├── _reminder_form.html.erb               # UI for configuring reminders
        └── _reminder_banner.html.erb             # Pro requirement banner (removed)

lib/
├── account_configs.rb                           # REMINDER_DURATIONS constant
└── submitters.rb                                # send_signature_requests (initial emails only)

config/
└── locales/
    └── i18n.yml                                 # Translations for reminder UI
```

---

## Hypotheses and Findings

| Hypothesis | Status | Key Findings |
|------------|--------|--------------|
| Reminders are scheduled when initial invitation is sent | **Disproven** | No code found in `SendSubmitterInvitationEmailJob` or `Submitters.send_signature_requests` that schedules reminders |
| Reminders are sent via a dedicated job | **Inconclusive** | No dedicated reminder job exists in `app/jobs/` directory |
| Reminders use the same email template as invitations | **Inconclusive** | No `reminder_email` method found in `SubmitterMailer`, only `invitation_email` |
| Reminder config (first_duration, second_duration, third_duration) is used to schedule jobs | **Disproven** | Configuration is saved but no code references these values to schedule reminder emails |
| Reminders are processed by a background service | **Disproven** | No service or scheduled task found that processes reminders |

---

## Detailed Findings

### 1. Reminder Configuration Infrastructure

**Location:** `app/controllers/notifications_settings_controller.rb`, `app/views/notifications_settings/_reminder_form.html.erb`

The system provides a UI for configuring email reminders:

```ruby
# app/controllers/notifications_settings_controller.rb
def load_reminder_config
  @reminder_config =
    AccountConfig.find_or_initialize_by(account: current_account, key: AccountConfig::SUBMITTER_REMINDERS)
end
```

The configuration stores three duration values:
- `first_duration` - Time until first reminder
- `second_duration` - Time until second reminder  
- `third_duration` - Time until third reminder

**Available durations** (from `lib/account_configs.rb`):
- `one_hour`, `two_hours`, `four_hours`, `eight_hours`, `twelve_hours`
- `twenty_four_hours`, `two_days`, `three_days`, `four_days`, `five_days`
- `six_days`, `seven_days`, `eight_days`, `fifteen_days`, `twenty_one_days`, `thirty_days`

### 2. Initial Invitation Email Flow

**Location:** `app/jobs/send_submitter_invitation_email_job.rb`, `lib/submitters.rb`

When a signature request is created, the initial invitation email is sent:

```ruby
# lib/submitters.rb
def send_signature_requests(submitters, delay_seconds: nil)
  submitters.each_with_index do |submitter, index|
    # ... validation checks ...
    
    if delay_seconds
      SendSubmitterInvitationEmailJob.perform_in((delay_seconds + index).seconds, 'submitter_id' => submitter.id)
    else
      SendSubmitterInvitationEmailJob.perform_async('submitter_id' => submitter.id)
    end
  end
end
```

The job sends the email and records the `sent_at` timestamp:

```ruby
# app/jobs/send_submitter_invitation_email_job.rb
def perform(params = {})
  submitter = Submitter.find(params['submitter_id'])
  # ... validation ...
  
  mail = SubmitterMailer.invitation_email(submitter)
  mail.deliver_now!
  
  SubmissionEvent.create!(submitter:, event_type: 'send_email')
  submitter.sent_at ||= Time.current
  submitter.save!
end
```

**Critical Finding:** This job does NOT schedule any reminder emails. It only sends the initial invitation.

### 3. Missing Reminder Scheduling Logic

**Expected Behavior (NOT FOUND):**
After sending the initial invitation, the system should:
1. Read the `SUBMITTER_REMINDERS` config for the account
2. Parse `first_duration`, `second_duration`, `third_duration` values
3. Convert duration strings (e.g., "two_days") to time intervals
4. Schedule reminder email jobs using `perform_at` or `perform_in` based on `submitter.sent_at + duration`

**Actual Behavior:**
- Configuration is saved successfully
- No code reads the reminder config after invitation is sent
- No reminder jobs are scheduled
- No reminder emails are sent

### 4. Event Tracking Infrastructure

**Location:** `app/models/submission_event.rb`

The system has infrastructure to track reminder emails:

```ruby
enum :event_type, {
  send_email: 'send_email',
  send_reminder_email: 'send_reminder_email',  # Defined but not used
  # ... other events
}
```

However, the `send_reminder_email` event type is never created in the codebase, suggesting reminders are not being sent.

### 5. Email Template Investigation

**Location:** `app/mailers/submitter_mailer.rb`

The `SubmitterMailer` class has these methods:
- `invitation_email` - Sends initial invitation
- `completed_email` - Sends completion notification
- `declined_email` - Sends decline notification
- `documents_copy_email` - Sends document copies
- `otp_verification_email` - Sends OTP codes

**No `reminder_email` method exists**, though there is a `SUBMITTER_INVITATION_REMINDER_EMAIL_KEY` config constant that suggests reminder email templates might be intended.

### 6. Configuration Storage

**Location:** `app/models/account_config.rb`

The reminder configuration is stored as:

```ruby
SUBMITTER_REMINDERS = 'submitter_reminders'
```

The value is stored as JSON with structure:
```json
{
  "first_duration": "two_days",
  "second_duration": "five_days", 
  "third_duration": "seven_days"
}
```

This configuration is successfully saved via `NotificationsSettingsController#create`, but is never read to schedule reminders.

---

## Prior Research Considered

- None (initial research on this topic)

---

## Recommendations & Next Steps

### Critical Finding: Reminder Functionality Is Incomplete

The reminder feature appears to be **partially implemented**:
- ✅ UI for configuration exists
- ✅ Configuration storage works
- ✅ Event tracking infrastructure exists
- ❌ **Reminder scheduling logic is missing**
- ❌ **Reminder email sending is missing**

### Implementation Recommendations

1. **Create Reminder Scheduling Logic:**
   - Modify `SendSubmitterInvitationEmailJob` to schedule reminder jobs after sending initial invitation
   - Or create a callback/observer that schedules reminders when `submitter.sent_at` is set

2. **Create Reminder Email Job:**
   - Create `SendSubmitterReminderEmailJob` similar to `SendSubmitterInvitationEmailJob`
   - Should check if submitter is still incomplete before sending
   - Should track which reminder number (first, second, third) is being sent

3. **Create Reminder Email Template:**
   - Add `reminder_email` method to `SubmitterMailer`
   - Use `SUBMITTER_INVITATION_REMINDER_EMAIL_KEY` config for custom templates
   - Or reuse `invitation_email` template with different subject

4. **Duration Parsing:**
   - Create utility to convert duration strings (e.g., "two_days") to time intervals
   - Handle cumulative timing (second reminder = first_duration + second_duration from sent_at)

5. **Prevent Duplicate Reminders:**
   - Track which reminders have been sent (e.g., via SubmissionEvent or submitter metadata)
   - Don't send reminder if submitter has completed
   - Don't send reminder if submission is archived

### Example Implementation Approach

```ruby
# In SendSubmitterInvitationEmailJob or a callback
def schedule_reminders(submitter)
  reminder_config = AccountConfig.find_by(
    account: submitter.account, 
    key: AccountConfig::SUBMITTER_REMINDERS
  )
  return unless reminder_config&.value.present?
  
  durations = reminder_config.value
  cumulative_time = 0
  
  [:first_duration, :second_duration, :third_duration].each_with_index do |duration_key, index|
    duration_str = durations[duration_key.to_s]
    next if duration_str.blank?
    
    cumulative_time += parse_duration(duration_str)
    reminder_number = index + 1
    
    SendSubmitterReminderEmailJob.perform_at(
      submitter.sent_at + cumulative_time,
      'submitter_id' => submitter.id,
      'reminder_number' => reminder_number
    )
  end
end
```

### Open Questions

1. Should reminders use the same email template as invitations or a separate template?
2. Should reminders be cumulative (second = first + second) or independent (second = second from sent_at)?
3. Should reminders stop if the submitter views the form but doesn't complete it?
4. Is there a maximum number of reminders that should be sent?
5. Should reminders respect the same email sending restrictions as invitations?

### Risks & Caveats

- **Current State:** Users can configure reminders, but they will never be sent. This is a broken feature.
- **User Expectation:** Users expect reminders to work after configuring them, creating a poor user experience.
- **Data Integrity:** The reminder configuration is being saved but never used, creating "dead" configuration data.
- **Testing:** No reminder functionality exists to test, so any implementation would need comprehensive testing.

---

