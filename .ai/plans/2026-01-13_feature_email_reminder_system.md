# [Feature Plan] Email Reminder System for Document Signing

**Date:** 2026-01-13
**Type:** feature
**Topic:** Email Reminder System Implementation
**Plan Author:** 
**Linked Research:** 2026-01-13_email_reminder_functionality.md

---

## 1. Objective

Implement a complete email reminder system that sends automated reminders to submitters who have not yet signed documents. The system builds on the existing reminder configuration system (`AccountConfig::SUBMITTER_REMINDERS`) and adds email template customization, reminder scheduling, and reminder sending functionality.

**Acceptance Criteria:**
- Three separate reminder email template forms exist in `/settings/personalization` below existing email templates
- Reminders are automatically scheduled when initial invitation is sent, using existing `first_duration`, `second_duration`, `third_duration` values
- Reminders are sent at independent intervals from sent_at (not cumulative)
- Each reminder uses its corresponding configured template (first reminder uses first template, etc.)
- Reminders stop only if submitter completes, rejects, or submission is terminated/archived
- Reminder events are tracked with event_type 'send_reminder_email' in SubmissionEvent
- All quality gates pass (linting, tests, qa.sh)

**Validation Methods:**
- Manual testing: Configure reminders, send invitation, verify reminders are scheduled and sent
- Unit tests: Test duration parsing, reminder scheduling, reminder sending logic
- Integration tests: Test end-to-end reminder flow
- Code review: Verify implementation follows existing patterns

---

## 2. Summary of Relevant Research

**Source:** `2026-01-13_email_reminder_functionality.md`

> The research revealed that while the UI and configuration infrastructure for reminders exists, **the actual reminder scheduling and sending functionality appears to be missing or incomplete**. The system has a configuration interface for setting reminder durations (first, second, third reminders) stored in `AccountConfig` with key `SUBMITTER_REMINDERS`, and event tracking for reminder emails (`send_reminder_email` event type), but **NO CODE** that actually schedules or sends reminder emails based on the configured durations. The initial invitation email is sent via `SendSubmitterInvitationEmailJob`, but there is no code that schedules follow-up reminder emails. The research recommends: (1) Create reminder scheduling logic in `SendSubmitterInvitationEmailJob`, (2) Create `SendSubmitterReminderEmailJob` similar to `SendSubmitterInvitationEmailJob`, (3) Add `reminder_email` method to `SubmitterMailer`, (4) Create utility to convert duration strings to time intervals, (5) Prevent duplicate reminders and respect completion/rejection status.

---

## 3. Implementation Plan

- [ ] **(Step 1) Create Duration Parsing Utility**
    - **Prerequisites:** None
    - **File:** `lib/account_configs.rb`
    - **Action:** Add `parse_reminder_duration` module function that converts duration strings from `REMINDER_DURATIONS` to `ActiveSupport::Duration`
    - **Details:**
      - Handle all duration strings: 'one_hour', 'two_hours', 'four_hours', 'eight_hours', 'twelve_hours', 'twenty_four_hours', 'two_days', 'three_days', 'four_days', 'five_days', 'six_days', 'seven_days', 'eight_days', 'fifteen_days', 'twenty_one_days', 'thirty_days'
      - Return `nil` for "none", blank, or invalid values
      - Use pattern matching or case statement to map strings to durations (e.g., "two_days" => 2.days)
    - **Acceptance Criteria:**
      - Function exists and is callable as `AccountConfigs.parse_reminder_duration('two_days')` returning `2.days`
      - All valid duration strings from `REMINDER_DURATIONS` are supported
      - Returns `nil` for invalid/blank values
      - Unit tests pass for all duration values
    - **Quality Gates:** Run tests, linting

- [ ] **(Step 2) Add Reminder Template Constants to AccountConfig**
    - **Prerequisites:** Step 1 complete
    - **File:** `app/models/account_config.rb`
    - **Action:** Add three new constants for reminder template keys and default values
    - **Details:**
      - Add `SUBMITTER_REMINDER_FIRST_EMAIL_KEY = 'submitter_reminder_first_email'`
      - Add `SUBMITTER_REMINDER_SECOND_EMAIL_KEY = 'submitter_reminder_second_email'`
      - Add `SUBMITTER_REMINDER_THIRD_EMAIL_KEY = 'submitter_reminder_third_email'`
      - Add default values in `DEFAULT_VALUES` hash for each key (subject and body)
      - Use appropriate I18n keys for default subject/body (may need to add translations)
    - **Acceptance Criteria:**
      - Three constants are defined in `AccountConfig`
      - Default values are added to `DEFAULT_VALUES` hash
      - Constants follow existing naming pattern
      - Code lints without errors
    - **Quality Gates:** Linting

- [ ] **(Step 3) Add Reminder Template Keys to PersonalizationSettingsController**
    - **Prerequisites:** Step 2 complete
    - **File:** `app/controllers/personalization_settings_controller.rb`
    - **Action:** Add the three reminder template keys to `ALLOWED_KEYS` array
    - **Details:**
      - Add `AccountConfig::SUBMITTER_REMINDER_FIRST_EMAIL_KEY` to `ALLOWED_KEYS`
      - Add `AccountConfig::SUBMITTER_REMINDER_SECOND_EMAIL_KEY` to `ALLOWED_KEYS`
      - Add `AccountConfig::SUBMITTER_REMINDER_THIRD_EMAIL_KEY` to `ALLOWED_KEYS`
      - Maintain alphabetical or logical ordering if pattern exists
    - **Acceptance Criteria:**
      - All three keys are in `ALLOWED_KEYS` array
      - Controller accepts these keys in `create` action
      - InvalidKey exception is not raised for these keys
      - Code lints without errors
    - **Quality Gates:** Linting, manual test that forms can save

- [ ] **(Step 4) Create First Reminder Template Form Partial**
    - **Prerequisites:** Step 3 complete
    - **File:** `app/views/personalization_settings/_reminder_first_email_form.html.erb` (NEW)
    - **Action:** Create form partial following pattern of `_signature_request_email_form.html.erb`
    - **Details:**
      - Use collapse component (`collapse collapse-plus bg-base-200 overflow-visible`)
      - Form uses `AccountConfigs.find_or_initialize_for_key(current_account, AccountConfig::SUBMITTER_REMINDER_FIRST_EMAIL_KEY)`
      - Form posts to `settings_personalization_path` with method `:post`
      - Include subject field (required, `base-input` class)
      - Include body field using `render 'personalization_settings/email_body_field'` partial
      - Include save button with `button_title` helper
      - Use appropriate translation key for title (e.g., `t('first_reminder_email')`)
    - **Acceptance Criteria:**
      - Form renders correctly in personalization settings page
      - Form saves subject and body to AccountConfig
      - Form follows same pattern as existing email template forms
      - Form validation works (required fields)
    - **Quality Gates:** Manual testing, linting

- [ ] **(Step 5) Create Second Reminder Template Form Partial**
    - **Prerequisites:** Step 4 complete
    - **File:** `app/views/personalization_settings/_reminder_second_email_form.html.erb` (NEW)
    - **Action:** Create form partial identical to Step 4 but for second reminder
    - **Details:**
      - Same structure as Step 4
      - Use `AccountConfig::SUBMITTER_REMINDER_SECOND_EMAIL_KEY`
      - Use translation key for second reminder (e.g., `t('second_reminder_email')`)
    - **Acceptance Criteria:**
      - Form renders correctly
      - Form saves independently from first reminder
      - Form follows same pattern
    - **Quality Gates:** Manual testing, linting

- [ ] **(Step 6) Create Third Reminder Template Form Partial**
    - **Prerequisites:** Step 5 complete
    - **File:** `app/views/personalization_settings/_reminder_third_email_form.html.erb` (NEW)
    - **Action:** Create form partial identical to Step 4 but for third reminder
    - **Details:**
      - Same structure as Step 4
      - Use `AccountConfig::SUBMITTER_REMINDER_THIRD_EMAIL_KEY`
      - Use translation key for third reminder (e.g., `t('third_reminder_email')`)
    - **Acceptance Criteria:**
      - Form renders correctly
      - Form saves independently from first and second reminders
      - Form follows same pattern
    - **Quality Gates:** Manual testing, linting

- [ ] **(Step 7) Add Reminder Template Forms to Personalization Settings View**
    - **Prerequisites:** Steps 4, 5, 6 complete
    - **File:** `app/views/personalization_settings/show.html.erb`
    - **Action:** Add three reminder template form renders below existing email templates
    - **Details:**
      - Add renders in the "Email Templates" section, after `submitter_completed_email_form`
      - Add: `<%= render 'reminder_first_email_form' %>`
      - Add: `<%= render 'reminder_second_email_form' %>`
      - Add: `<%= render 'reminder_third_email_form' %>`
      - Maintain spacing with `space-y-4` class if used
    - **Acceptance Criteria:**
      - All three reminder forms appear in personalization settings page
      - Forms are below existing email templates
      - Forms are in correct order (first, second, third)
      - Page renders without errors
    - **Quality Gates:** Manual testing, linting

- [ ] **(Step 8) Add Reminder Email Method to SubmitterMailer**
    - **Prerequisites:** Step 2 complete
    - **File:** `app/mailers/submitter_mailer.rb`
    - **Action:** Add `reminder_email` method that accepts submitter and reminder_number (1, 2, or 3)
    - **Details:**
      - Method signature: `def reminder_email(submitter, reminder_number:)`
      - Select appropriate template config key based on reminder_number (1 => FIRST, 2 => SECOND, 3 => THIRD)
      - Load email config using `AccountConfigs.find_for_account` with appropriate key
      - Set `@current_account`, `@submitter`, `@subject`, `@body` similar to `invitation_email`
      - Use `fetch_config_email_body` helper for body fallback
      - Use `ReplaceEmailVariables.call` for both subject and body to support email variables (like invitation_email does)
      - Use `build_invite_subject` or create similar helper that uses `ReplaceEmailVariables.call` for subject
      - Use `from_address_for_submitter` for from address
      - Use `build_submitter_reply_to` for reply_to
      - Call `assign_message_metadata('submitter_reminder', @submitter)`
      - Use `I18n.with_locale` for locale support
      - Return mail object with `mail(to:, from:, subject:, reply_to:)`
      - Note: Email variables are automatically processed in the view template via `_custom_content` partial
    - **Acceptance Criteria:**
      - Method exists and accepts submitter and reminder_number
      - Method loads correct template based on reminder_number
      - Method returns valid mail object
      - Method follows same pattern as `invitation_email`
      - Unit tests pass
    - **Quality Gates:** Unit tests, linting

- [ ] **(Step 9) Create SendSubmitterReminderEmailJob**
    - **Prerequisites:** Step 8 complete
    - **File:** `app/jobs/send_submitter_reminder_email_job.rb` (NEW)
    - **Action:** Create new Sidekiq job to send reminder emails
    - **Details:**
      - Include `Sidekiq::Job`
      - `perform` method accepts params with 'submitter_id' and 'reminder_number'
      - Check if submitter is still incomplete: `return if submitter.completed_at?`
      - Check if submitter has rejected: `return if submitter.declined_at?`
      - Check if submission is archived: `return if submitter.submission.archived_at?`
      - Check if template is archived: `return if submitter.template&.archived_at?`
      - Check email sending permissions: `return if submitter.submission.source == 'invite' && !Accounts.can_send_emails?(submitter.account, on_events: true)`
      - Check invitation email permissions: `return unless Accounts.can_send_invitation_emails?(submitter.account)`
      - **Idempotency check:** Check if reminder event already exists for this submitter and reminder_number to prevent duplicates on retry:
        - `return if SubmissionEvent.exists?(submitter: submitter, event_type: 'send_reminder_email', data: { 'reminder_number' => params['reminder_number'] })`
        - Or check if reminder was sent recently (within last hour) for same reminder_number
      - Call `SubmitterMailer.reminder_email(submitter, reminder_number: params['reminder_number'])`
      - Call `Submitters::ValidateSending.call(submitter, mail)`
      - Deliver mail with `mail.deliver_now!`
      - Create `SubmissionEvent` with `event_type: 'send_reminder_email'` and include reminder_number in data:
        - `SubmissionEvent.create!(submitter:, event_type: 'send_reminder_email', data: { 'reminder_number' => params['reminder_number'] })`
      - Handle errors gracefully (log to Rollbar if defined)
    - **Acceptance Criteria:**
      - Job exists and can be enqueued
      - Job sends reminder email using correct template
      - Job respects all validation checks
      - Job creates SubmissionEvent with correct event_type and reminder_number in data
      - Job handles edge cases (completed, rejected, archived)
      - Job prevents duplicate reminders on retry (idempotency check)
      - Unit tests pass
    - **Quality Gates:** Unit tests, linting

- [ ] **(Step 10) Add Reminder Scheduling Logic to SendSubmitterInvitationEmailJob**
    - **Prerequisites:** Steps 1, 9 complete
    - **File:** `app/jobs/send_submitter_invitation_email_job.rb`
    - **Action:** Add reminder scheduling after invitation email is sent
    - **Details:**
      - After `submitter.save!`, call new method `schedule_reminders(submitter)`
      - Create private method `schedule_reminders(submitter)`
      - Load reminder config: `reminder_config = AccountConfig.find_by(account: submitter.account, key: AccountConfig::SUBMITTER_REMINDERS)`
      - Return early if config is blank or value is blank
      - Parse durations from config value: `durations = reminder_config.value`
      - For each duration key (`first_duration`, `second_duration`, `third_duration`):
        - Get duration string: `duration_str = durations[duration_key.to_s]`
        - Skip if blank or "none"
        - Parse duration: `parsed_duration = AccountConfigs.parse_reminder_duration(duration_str)`
        - Skip if parsing returns nil
        - Calculate reminder number (1, 2, or 3 based on key)
        - Schedule job: `SendSubmitterReminderEmailJob.perform_at(submitter.sent_at + parsed_duration, 'submitter_id' => submitter.id, 'reminder_number' => reminder_number)`
      - Use independent timing (each duration from sent_at, not cumulative)
    - **Acceptance Criteria:**
      - Reminders are scheduled after invitation is sent
      - Only configured reminders are scheduled (skips "none" or blank)
      - Reminders use independent timing (not cumulative)
      - Reminder jobs are scheduled with correct parameters
      - Unit tests pass
    - **Quality Gates:** Unit tests, linting

- [ ] **(Step 11) Add Translations for Reminder Templates**
    - **Prerequisites:** Steps 4, 5, 6 complete
    - **File:** `config/locales/i18n.yml`
    - **Action:** Add translation keys for reminder template forms
    - **Details:**
      - Add `first_reminder_email: "First Reminder Email"` (and translations for other locales)
      - Add `second_reminder_email: "Second Reminder Email"`
      - Add `third_reminder_email: "Third Reminder Email"`
      - Add default subject/body translations if needed for DEFAULT_VALUES
      - Follow existing translation pattern in file
    - **Acceptance Criteria:**
      - All reminder template form titles are translated
      - Translations exist for all supported locales
      - Default values use appropriate translations
      - No missing translation errors
    - **Quality Gates:** Manual testing, linting

- [ ] **(Step 12) Write Tests for Duration Parsing Utility**
    - **Prerequisites:** Step 1 complete
    - **File:** `spec/lib/account_configs_spec.rb` (create if doesn't exist) or add to existing spec
    - **Action:** Write comprehensive tests for `parse_reminder_duration`
    - **Details:**
      - Test all valid duration strings return correct ActiveSupport::Duration
      - Test invalid/blank values return nil
      - Test "none" returns nil
      - Test edge cases
    - **Acceptance Criteria:**
      - All tests pass
      - Test coverage is comprehensive
      - Tests follow existing spec patterns
    - **Quality Gates:** Run tests, verify coverage

- [ ] **(Step 13) Write Tests for Reminder Scheduling**
    - **Prerequisites:** Step 10 complete
    - **File:** `spec/jobs/send_submitter_invitation_email_job_spec.rb` (create or extend)
    - **Action:** Write tests for reminder scheduling logic
    - **Details:**
      - Test reminders are scheduled when config exists
      - Test reminders are not scheduled when config is blank
      - Test only configured reminders are scheduled (skips "none")
      - Test independent timing (each from sent_at)
      - Test reminder jobs are enqueued with correct parameters
    - **Acceptance Criteria:**
      - All tests pass
      - Tests cover all scheduling scenarios
      - Tests follow existing spec patterns
    - **Quality Gates:** Run tests, verify coverage

- [ ] **(Step 14) Write Tests for SendSubmitterReminderEmailJob**
    - **Prerequisites:** Step 9 complete
    - **File:** `spec/jobs/send_submitter_reminder_email_job_spec.rb` (NEW)
    - **Action:** Write comprehensive tests for reminder email job
    - **Details:**
      - Test reminder email is sent when submitter is incomplete
      - Test reminder email is not sent when submitter is completed
      - Test reminder email is not sent when submitter is rejected
      - Test reminder email is not sent when submission is archived
      - Test correct template is used based on reminder_number
      - Test SubmissionEvent is created with correct event_type and reminder_number in data
      - Test email sending permissions are respected
      - Test idempotency check prevents duplicate reminders on retry
      - Test email variables are processed correctly in reminder templates
    - **Acceptance Criteria:**
      - All tests pass
      - Tests cover all validation scenarios
      - Tests follow existing spec patterns
    - **Quality Gates:** Run tests, verify coverage

- [ ] **(Step 15) Run Quality Gates and Final Verification**
    - **Prerequisites:** All previous steps complete
    - **Action:** Run all quality gates and perform final manual testing
    - **Details:**
      - Run `qa.sh` script
      - Run linter (ESLint, RuboCop, etc.)
      - Run all tests
      - Manual testing: Configure reminders, send invitation, verify reminders are sent
      - Verify reminder events appear in SubmissionEvent
      - Verify reminders stop when submitter completes/rejects
    - **Acceptance Criteria:**
      - All quality gates pass
      - All tests pass
      - Manual testing confirms end-to-end functionality works
      - No linting errors
    - **Quality Gates:** qa.sh, linting, tests, manual verification

---

## 4. Risks / Caveats

**Identified Risks:**
- **Job retry may cause duplicate reminders** - **Mitigation:** ✅ ADDED - Idempotency check in Step 9 that checks for existing SubmissionEvent with same reminder_number before sending
- **Submitter completes between scheduling and sending** - **Mitigation:** Job already checks `completed_at?` before sending
- **Duration parsing fails for unexpected values** - **Mitigation:** Return nil for invalid values, skip scheduling
- **Template not configured for reminder** - **Mitigation:** Use default values from DEFAULT_VALUES hash
- **Performance impact of scheduling multiple jobs** - **Mitigation:** Jobs are async, minimal impact expected

**Assumptions:**
- Existing reminder configuration system (`SUBMITTER_REMINDERS`) will continue to work as-is
- `AccountConfigs.find_for_account` and `find_or_initialize_for_key` methods work correctly
- `Accounts.can_send_invitation_emails?` and `can_send_emails?` methods are reliable
- Sidekiq job scheduling (`perform_at`) works correctly
- SubmissionEvent tracking is working correctly

**Potential Blockers:**
- Missing I18n translations may cause errors (mitigated by Step 11)
- Existing code patterns may not be fully understood (mitigated by codebase exploration)
- Sidekiq configuration issues (should be already working for other jobs)

**Uncertainties:**
- ~~Whether reminder templates should support email variables/placeholders~~ - ✅ RESOLVED: Yes, following invitation_email pattern using ReplaceEmailVariables.call
- ~~Whether reminders should be idempotent~~ - ✅ RESOLVED: Yes, added idempotency check in Step 9
- Whether reminder scheduling should be transactional with invitation sending - Low risk, jobs are async

---

## 5. References & Links

- [Research: 2026-01-13_email_reminder_functionality.md](../research/2026-01-13_email_reminder_functionality.md)
- [Ticket: 2026-01-13_feature_email_reminder_system.md](../tickets/2026-01-13_feature_email_reminder_system.md)
- `app/jobs/send_submitter_invitation_email_job.rb` - Reference for job pattern
- `app/mailers/submitter_mailer.rb` - Reference for email template methods
- `app/views/personalization_settings/_signature_request_email_form.html.erb` - Template for form structure
- `app/controllers/personalization_settings_controller.rb` - Controller for template saving
- `app/models/account_config.rb` - AccountConfig model with constants
- `lib/account_configs.rb` - AccountConfigs module with REMINDER_DURATIONS
- `app/controllers/notifications_settings_controller.rb` - Existing reminder config controller
- `app/views/notifications_settings/_reminder_form.html.erb` - Existing reminder duration form

---

## 6. Review & Next Steps

- [x] ✅ **Validate consistency with research findings** - COMPLETED: Plan aligns with research recommendations. All research findings addressed:
  - Reminder scheduling logic added to SendSubmitterInvitationEmailJob (Step 10)
  - SendSubmitterReminderEmailJob created (Step 9)
  - reminder_email method added to SubmitterMailer (Step 8)
  - Duration parsing utility created (Step 1)
  - Duplicate prevention via idempotency check (Step 9)
  - Uses existing SUBMITTER_REMINDERS config (Step 10)
- [x] ✅ **Verify all steps are specific and executable** - COMPLETED: All 15 steps have:
  - Clear file paths and locations
  - Specific actions to take
  - Detailed implementation notes
  - Prerequisites clearly defined
  - Quality gates specified
- [x] ✅ **Confirm acceptance criteria are measurable** - COMPLETED: All acceptance criteria are:
  - Specific and testable (e.g., "Function exists and is callable", "All tests pass")
  - Verifiable (e.g., "Form renders correctly", "Job creates SubmissionEvent")
  - Include validation methods (unit tests, manual testing, linting)
- [x] ✅ **Consider adding idempotency check** - COMPLETED: Added to Step 9
  - Checks for existing SubmissionEvent with same reminder_number before sending
  - Prevents duplicate reminders on job retry
  - Includes reminder_number in SubmissionEvent data for tracking
- [x] ✅ **Consider adding email variable support** - COMPLETED: Added to Step 8
  - Uses ReplaceEmailVariables.call for subject and body (following invitation_email pattern)
  - Email variables automatically processed via _custom_content partial in view
  - Supports all existing email variables (submitter.link, template.name, etc.)
- [x] ✅ **Update plan as needed** - COMPLETED: Plan updated with:
  - Idempotency check details in Step 9
  - Email variable support in Step 8
  - Updated test requirements to include idempotency and variable testing
  - Resolved uncertainties in Risks section
- [ ] Proceed to execution only after review approval

---

**Note:** This plan should be reviewed using the `criticize_plan` command before execution. Execute using the `execute_plan` command, which will validate consistency with research and ensure quality gates are met.

