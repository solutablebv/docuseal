# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SendSubmitterInvitationEmailJob do
    let(:account) { create(:account) }
    let(:user) { create(:user, account:) }
    let(:template) { create(:template, account:, author: user) }
    let(:submission) { create(:submission, :with_submitters, template:, created_by_user: user) }
    let(:submitter) { submission.submitters.first }

    before do
        create(:encrypted_config, key: EncryptedConfig::ESIGN_CERTS_KEY,
                                  value: GenerateCertificate.call.transform_values(&:to_pem))
    end

    describe '#perform' do
        context 'when reminder config exists' do
            let!(:reminder_config) do
                create(:account_config, account:,
                       key: AccountConfig::SUBMITTER_REMINDERS,
                       value: {
                           'first_duration' => 'two_days',
                           'second_duration' => 'three_days',
                           'third_duration' => 'four_days'
                       })
            end

            it 'schedules reminder jobs with independent timing' do
                freeze_time do
                    described_class.new.perform('submitter_id' => submitter.id)

                    submitter.reload
                    expect(submitter.sent_at).to be_within(1.second).of(Time.current)

                    scheduled_jobs = SendSubmitterReminderEmailJob.jobs

                    expect(scheduled_jobs.size).to eq(3)

                    first_job = scheduled_jobs.find { |j| j['args'].first['reminder_number'] == 1 }
                    second_job = scheduled_jobs.find { |j| j['args'].first['reminder_number'] == 2 }
                    third_job = scheduled_jobs.find { |j| j['args'].first['reminder_number'] == 3 }

                    expect(first_job['at']).to be_within(1.second).of(submitter.sent_at + 2.days)
                    expect(second_job['at']).to be_within(1.second).of(submitter.sent_at + 3.days)
                    expect(third_job['at']).to be_within(1.second).of(submitter.sent_at + 4.days)
                end
            end

            it 'schedules only configured reminders' do
                reminder_config.update(value: {
                                          'first_duration' => 'two_days',
                                          'second_duration' => 'none',
                                          'third_duration' => 'four_days'
                                      })

                described_class.new.perform('submitter_id' => submitter.id)

                scheduled_jobs = SendSubmitterReminderEmailJob.jobs
                expect(scheduled_jobs.size).to eq(2)
                expect(scheduled_jobs.map { |j| j['args'].first['reminder_number'] }).to contain_exactly(1, 3)
            end

            it 'does not schedule reminders when all durations are none or blank' do
                reminder_config.update(value: {
                                          'first_duration' => 'none',
                                          'second_duration' => '',
                                          'third_duration' => nil
                                      })

                described_class.new.perform('submitter_id' => submitter.id)

                expect(SendSubmitterReminderEmailJob.jobs.size).to eq(0)
            end
        end

        context 'when reminder config does not exist' do
            it 'does not schedule reminder jobs' do
                described_class.new.perform('submitter_id' => submitter.id)

                expect(SendSubmitterReminderEmailJob.jobs.size).to eq(0)
            end
        end

        context 'when reminder config value is blank' do
            let!(:reminder_config) do
                create(:account_config, account:,
                       key: AccountConfig::SUBMITTER_REMINDERS,
                       value: nil)
            end

            it 'does not schedule reminder jobs' do
                described_class.new.perform('submitter_id' => submitter.id)

                expect(SendSubmitterReminderEmailJob.jobs.size).to eq(0)
            end
        end
    end
end

