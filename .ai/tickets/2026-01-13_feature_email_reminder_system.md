# [Feature] Email Reminder System for Document Signing

**Date Created:** 2026-01-13
**Type:** feature
**Priority:** high
**Status:** open
**Author:** Gydo Broos

---

## Description

Implement a complete email reminder system that sends automated reminders to submitters who have not yet signed documents. The system builds on the **existing reminder configuration system** (`AccountConfig::SUBMITTER_REMINDERS`) that is already configured in `/settings/notifications`. This ticket adds the missing functionality to actually schedule and send reminders using the existing configuration, and adds email template customization for each reminder in `/settings/personalization`.

**User Story:**
As an administrator, I want to configure automated email reminders with custom templates for submitters who haven't signed documents, so that I can increase completion rates and maintain consistent communication.

**Current Behavior:**
- **Existing reminder configuration system** (`AccountConfig::SUBMITTER_REMINDERS`) exists in `/settings/notifications`
- Administrators can configure `first_duration`, `second_duration`, `third_duration` using `AccountConfigs::REMINDER_DURATIONS`
- Configuration is saved via `NotificationsSettingsController` but reminders are never sent
- No reminder email templates exist in personalization settings
- No reminder scheduling or sending logic exists

**Expected Behavior:**
- **Uses existing reminder configuration** from `AccountConfig::SUBMITTER_REMINDERS` (configured in `/settings/notifications`)
- Administrators can configure three separate reminder email templates in `/settings/personalization` (first, second, third reminders)
- Reminders are automatically scheduled when initial invitation is sent, using the existing `first_duration`, `second_duration`, `third_duration` values
- Reminders are sent at independent intervals from sent_at using the existing duration configuration
- Each reminder uses its corresponding configured template (first reminder uses first template, etc.)
- Reminders stop only if submitter completes, rejects, or submission is terminated/archived
- Reminders continue even if submitter views the form but doesn't complete it
- Reminder events are tracked in SubmissionEvent

---

## Acceptance Criteria

- [ ] Three separate reminder email template configuration forms are added to `/settings/personalization` below existing email templates
- [ ] First reminder template form is created and functional
- [ ] Second reminder template form is created and functional
- [ ] Third reminder template form is created and functional
- [ ] Templates follow the same pattern as existing email templates (subject, body fields)
- [ ] Reminder templates are stored in AccountConfig with appropriate keys
- [ ] Reminder scheduling logic reads from existing `AccountConfig::SUBMITTER_REMINDERS` configuration
- [ ] Reminder scheduling logic is implemented in SendSubmitterInvitationEmailJob or callback
- [ ] Scheduling uses existing `first_duration`, `second_duration`, `third_duration` values from reminder config
- [ ] Duration parsing utility converts existing duration strings (from `AccountConfigs::REMINDER_DURATIONS`) to time intervals
- [ ] New SendSubmitterReminderEmailJob is created to send reminder emails
- [ ] Reminder job checks if submitter is still incomplete before sending
- [ ] Reminder job uses the appropriate template based on reminder number (1st, 2nd, 3rd)
- [ ] Reminder emails are scheduled with independent timing (each duration calculated from sent_at, not cumulative)
- [ ] First reminder is scheduled at sent_at + first_duration (from existing config)
- [ ] Second reminder is scheduled at sent_at + second_duration (from existing config)
- [ ] Third reminder is scheduled at sent_at + third_duration (from existing config)
- [ ] If a duration is set to "none" or blank in existing config, that reminder is not scheduled
- [ ] Reminder emails respect the same validation and sending restrictions as invitation emails
- [ ] Reminder events are tracked with event_type 'send_reminder_email' in SubmissionEvent
- [ ] Reminders are not sent if submitter has completed the document
- [ ] Reminders are not sent if submitter has rejected the document
- [ ] Reminders are not sent if submission is archived or terminated
- [ ] Reminders are sent even if submitter has viewed the form but not completed it
- [ ] Reminder templates are added to PersonalizationSettingsController ALLOWED_KEYS
- [ ] Reminder mailer method is added to SubmitterMailer
- [ ] Duration parsing utility converts duration strings to time intervals
- [ ] Tests are written for reminder scheduling and sending
- [ ] All quality gates pass (linting, tests, qa.sh)

**Definition of Done:**
- All acceptance criteria are met
- Code is reviewed and approved
- Tests are written and passing
- Documentation is updated (if applicable)
- Quality gates are passed (linting, tests, qa.sh)

---

## Technical Details

### Affected Areas
- `app/controllers/personalization_settings_controller.rb` - Add reminder template keys to ALLOWED_KEYS
- `app/views/personalization_settings/show.html.erb` - Add reminder template forms
- `app/views/personalization_settings/` - Create new partials for reminder template forms
- `app/models/account_config.rb` - Add reminder template config keys:
  - `SUBMITTER_REMINDER_FIRST_EMAIL_KEY = 'submitter_reminder_first_email'`
  - `SUBMITTER_REMINDER_SECOND_EMAIL_KEY = 'submitter_reminder_second_email'`
  - `SUBMITTER_REMINDER_THIRD_EMAIL_KEY = 'submitter_reminder_third_email'`
  - Add default values for each reminder template in DEFAULT_VALUES hash
- `app/jobs/send_submitter_invitation_email_job.rb` - Add reminder scheduling logic that uses existing `AccountConfig::SUBMITTER_REMINDERS`
- `app/jobs/send_submitter_reminder_email_job.rb` - **NEW FILE** - Create reminder email job
- `app/mailers/submitter_mailer.rb` - Add reminder_email method
- `lib/account_configs.rb` - Add duration parsing utility to convert `REMINDER_DURATIONS` strings to ActiveSupport::Duration
- `config/locales/i18n.yml` - Add translations for reminder templates
- **Existing system (no changes needed):**
  - `app/controllers/notifications_settings_controller.rb` - Already handles reminder config saving
  - `app/views/notifications_settings/_reminder_form.html.erb` - Already provides reminder duration configuration UI
  - `AccountConfig::SUBMITTER_REMINDERS` - Already stores reminder durations
  - `AccountConfigs::REMINDER_DURATIONS` - Already defines available duration options

### Implementation Notes

**Reminder Template Configuration:**
- Follow the pattern of existing email templates (signature_request_email_form, documents_copy_email_form, etc.)
- Use collapse component for each reminder template (three separate forms)
- Store templates in AccountConfig with keys:
  - `submitter_reminder_first_email`
  - `submitter_reminder_second_email`
  - `submitter_reminder_third_email`
- Each template has subject and body fields
- Templates are added to PersonalizationSettingsController ALLOWED_KEYS

**Reminder Scheduling (Uses Existing Config):**
- After initial invitation is sent (in SendSubmitterInvitationEmailJob), read **existing** `AccountConfig::SUBMITTER_REMINDERS` config
- Parse `first_duration`, `second_duration`, `third_duration` values from existing config (already stored in AccountConfig)
- Use duration parsing utility to convert duration strings from `AccountConfigs::REMINDER_DURATIONS` to ActiveSupport::Duration (e.g., "two_days" => 2.days)
- Only schedule reminders for durations that are configured (not "none" or blank)
- Schedule reminders with INDEPENDENT timing (not cumulative):
  - First reminder: perform_at(submitter.sent_at + parsed_first_duration, reminder_number: 1) if first_duration is set
  - Second reminder: perform_at(submitter.sent_at + parsed_second_duration, reminder_number: 2) if second_duration is set
  - Third reminder: perform_at(submitter.sent_at + parsed_third_duration, reminder_number: 3) if third_duration is set
- Track which reminders have been scheduled to prevent duplicates
- The existing reminder configuration in `/settings/notifications` continues to work as-is

**Reminder Sending:**
- SendSubmitterReminderEmailJob should:
  - Check if submitter is still incomplete (completed_at is nil)
  - Check if submitter has rejected the document (declined_at is nil)
  - Check if submission is archived or terminated
  - Validate email sending permissions (same as invitation)
  - Use appropriate reminder template based on reminder number (1st, 2nd, 3rd)
  - Create SubmissionEvent with event_type 'send_reminder_email'
  - Handle errors gracefully
  - Note: Reminders are sent even if submitter has viewed the form (view_form event exists) but not completed it

**Duration Parsing (Uses Existing REMINDER_DURATIONS):**
- Create utility function in `lib/account_configs.rb` to convert duration strings to ActiveSupport::Duration
- Use existing `AccountConfigs::REMINDER_DURATIONS` constant which defines all available durations:
  - 'one_hour', 'two_hours', 'four_hours', 'eight_hours', 'twelve_hours', 'twenty_four_hours'
  - 'two_days', 'three_days', 'four_days', 'five_days', 'six_days', 'seven_days', 'eight_days'
  - 'fifteen_days', 'twenty_one_days', 'thirty_days'
- Handle "none" or blank values (don't schedule reminder)
- Support independent timing (each reminder = its duration from sent_at, not cumulative)
- Note: Multitenant accounts exclude 'one_hour' and 'two_hours' options (already handled in existing form)

### Related Code References
- `app/views/personalization_settings/_signature_request_email_form.html.erb` - Template for email form structure
- `app/jobs/send_submitter_invitation_email_job.rb` - Reference for email job pattern
- `app/mailers/submitter_mailer.rb` - Reference for email template methods
- **Existing Reminder Configuration System:**
  - `app/controllers/notifications_settings_controller.rb` - Handles saving reminder duration config
  - `app/views/notifications_settings/_reminder_form.html.erb` - UI for configuring reminder durations
  - `app/models/account_config.rb` - `SUBMITTER_REMINDERS` constant and storage
  - `lib/account_configs.rb` - `REMINDER_DURATIONS` constant with all available duration options

---

## Related Context

### Linked Research
- [Research: 2026-01-13_email_reminder_functionality.md](../research/2026-01-13_email_reminder_functionality.md)

### Linked Plans
- None

### Related Tickets
- None

---

## Additional Information

### Environment
- Development, staging, production

### Screenshots or Examples
- Reference existing email template forms in `/settings/personalization` for UI pattern

### Notes
- **Decisions Made:**
  - Three separate templates for first, second, and third reminders (Option A)
  - Independent timing - each reminder calculated from sent_at, not cumulative (Option B)
  - Reminders stop only if document is rejected, terminated, or signed - NOT if just viewed

- **Implementation Considerations:**
  - **Must use existing reminder configuration system** - Read from `AccountConfig::SUBMITTER_REMINDERS` which is already configured in `/settings/notifications`
  - The existing reminder duration configuration UI continues to work - we're adding the missing scheduling/sending functionality
  - Need to handle edge cases: submitter completes/rejects between scheduling and sending
  - Need to prevent duplicate reminders if job is retried
  - Should respect same email sending restrictions as invitations
  - Track reminder number (1, 2, 3) in job parameters to select correct template
  - Check submitter.declined_at to prevent sending to rejected submitters
  - Check submission.archived_at to prevent sending for terminated submissions
  - Only schedule reminders for durations that are configured (handle "none" or blank values)
  - Duration parsing must support all values in existing `AccountConfigs::REMINDER_DURATIONS` constant

---

## Work Log

### History
- 2026-01-13: Ticket created

### Current Status
- Open - Ready for implementation
- Clarifications received: Three separate templates, independent timing, reminders stop only on completion/rejection/termination

