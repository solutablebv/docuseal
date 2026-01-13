# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SendSubmitterReminderEmailJob do
    let(:account) { create(:account) }
    let(:user) { create(:user, account:) }
    let(:template) { create(:template, account:, author: user) }
    let(:submission) { create(:submission, :with_submitters, template:, created_by_user: user) }
    let(:submitter) { submission.submitters.first }

    before do
        create(:encrypted_config, key: EncryptedConfig::ESIGN_CERTS_KEY,
                                  value: GenerateCertificate.call.transform_values(&:to_pem))
        submitter.update(sent_at: 1.day.ago)
    end

    describe '#perform' do
        context 'when submitter is incomplete' do
            it 'sends reminder email using correct template' do
                expect(SubmitterMailer).to receive(:reminder_email).with(submitter, reminder_number: 1).and_call_original

                mail = double('mail')
                allow(SubmitterMailer).to receive(:reminder_email).and_return(mail)
                allow(Submitters::ValidateSending).to receive(:call)
                allow(mail).to receive(:deliver_now!)

                described_class.new.perform('submitter_id' => submitter.id, 'reminder_number' => 1)

                expect(Submitters::ValidateSending).to have_received(:call).with(submitter, mail)
                expect(mail).to have_received(:deliver_now!)
            end

            it 'creates SubmissionEvent with correct event_type and reminder_number' do
                mail = double('mail')
                allow(SubmitterMailer).to receive(:reminder_email).and_return(mail)
                allow(Submitters::ValidateSending).to receive(:call)
                allow(mail).to receive(:deliver_now!)

                expect do
                    described_class.new.perform('submitter_id' => submitter.id, 'reminder_number' => 2)
                end.to change(SubmissionEvent, :count).by(1)

                event = SubmissionEvent.last
                expect(event.event_type).to eq('send_reminder_email')
                expect(event.submitter).to eq(submitter)
                expect(event.data['reminder_number']).to eq(2)
            end

            it 'uses first reminder template for reminder_number 1' do
                mail = double('mail')
                allow(SubmitterMailer).to receive(:reminder_email).with(submitter, reminder_number: 1).and_return(mail)
                allow(Submitters::ValidateSending).to receive(:call)
                allow(mail).to receive(:deliver_now!)

                described_class.new.perform('submitter_id' => submitter.id, 'reminder_number' => 1)

                expect(SubmitterMailer).to have_received(:reminder_email).with(submitter, reminder_number: 1)
            end

            it 'uses second reminder template for reminder_number 2' do
                mail = double('mail')
                allow(SubmitterMailer).to receive(:reminder_email).with(submitter, reminder_number: 2).and_return(mail)
                allow(Submitters::ValidateSending).to receive(:call)
                allow(mail).to receive(:deliver_now!)

                described_class.new.perform('submitter_id' => submitter.id, 'reminder_number' => 2)

                expect(SubmitterMailer).to have_received(:reminder_email).with(submitter, reminder_number: 2)
            end

            it 'uses third reminder template for reminder_number 3' do
                mail = double('mail')
                allow(SubmitterMailer).to receive(:reminder_email).with(submitter, reminder_number: 3).and_return(mail)
                allow(Submitters::ValidateSending).to receive(:call)
                allow(mail).to receive(:deliver_now!)

                described_class.new.perform('submitter_id' => submitter.id, 'reminder_number' => 3)

                expect(SubmitterMailer).to have_received(:reminder_email).with(submitter, reminder_number: 3)
            end
        end

        context 'when submitter is completed' do
            before do
                submitter.update(completed_at: Time.current)
            end

            it 'does not send reminder email' do
                expect(SubmitterMailer).not_to receive(:reminder_email)

                described_class.new.perform('submitter_id' => submitter.id, 'reminder_number' => 1)
            end
        end

        context 'when submitter is rejected' do
            before do
                submitter.update(declined_at: Time.current)
            end

            it 'does not send reminder email' do
                expect(SubmitterMailer).not_to receive(:reminder_email)

                described_class.new.perform('submitter_id' => submitter.id, 'reminder_number' => 1)
            end
        end

        context 'when submission is archived' do
            before do
                submission.update(archived_at: Time.current)
            end

            it 'does not send reminder email' do
                expect(SubmitterMailer).not_to receive(:reminder_email)

                described_class.new.perform('submitter_id' => submitter.id, 'reminder_number' => 1)
            end
        end

        context 'when template is archived' do
            before do
                template.update(archived_at: Time.current)
            end

            it 'does not send reminder email' do
                expect(SubmitterMailer).not_to receive(:reminder_email)

                described_class.new.perform('submitter_id' => submitter.id, 'reminder_number' => 1)
            end
        end

        context 'idempotency check' do
            it 'prevents duplicate reminders on retry' do
                mail = double('mail')
                allow(SubmitterMailer).to receive(:reminder_email).and_return(mail)
                allow(Submitters::ValidateSending).to receive(:call)
                allow(mail).to receive(:deliver_now!)

                # First call
                described_class.new.perform('submitter_id' => submitter.id, 'reminder_number' => 1)
                expect(SubmitterMailer).to have_received(:reminder_email).once

                # Second call (retry) - should not send again
                described_class.new.perform('submitter_id' => submitter.id, 'reminder_number' => 1)
                expect(SubmitterMailer).to have_received(:reminder_email).once
            end

            it 'allows different reminder numbers to be sent' do
                mail = double('mail')
                allow(SubmitterMailer).to receive(:reminder_email).and_return(mail)
                allow(Submitters::ValidateSending).to receive(:call)
                allow(mail).to receive(:deliver_now!)

                described_class.new.perform('submitter_id' => submitter.id, 'reminder_number' => 1)
                described_class.new.perform('submitter_id' => submitter.id, 'reminder_number' => 2)

                expect(SubmitterMailer).to have_received(:reminder_email).twice
            end
        end
    end
end

