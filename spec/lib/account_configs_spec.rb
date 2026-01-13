# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountConfigs do
    describe '.parse_reminder_duration' do
        it 'returns correct duration for one_hour' do
            expect(AccountConfigs.parse_reminder_duration('one_hour')).to eq(1.hour)
        end

        it 'returns correct duration for two_hours' do
            expect(AccountConfigs.parse_reminder_duration('two_hours')).to eq(2.hours)
        end

        it 'returns correct duration for four_hours' do
            expect(AccountConfigs.parse_reminder_duration('four_hours')).to eq(4.hours)
        end

        it 'returns correct duration for eight_hours' do
            expect(AccountConfigs.parse_reminder_duration('eight_hours')).to eq(8.hours)
        end

        it 'returns correct duration for twelve_hours' do
            expect(AccountConfigs.parse_reminder_duration('twelve_hours')).to eq(12.hours)
        end

        it 'returns correct duration for twenty_four_hours' do
            expect(AccountConfigs.parse_reminder_duration('twenty_four_hours')).to eq(24.hours)
        end

        it 'returns correct duration for two_days' do
            expect(AccountConfigs.parse_reminder_duration('two_days')).to eq(2.days)
        end

        it 'returns correct duration for three_days' do
            expect(AccountConfigs.parse_reminder_duration('three_days')).to eq(3.days)
        end

        it 'returns correct duration for four_days' do
            expect(AccountConfigs.parse_reminder_duration('four_days')).to eq(4.days)
        end

        it 'returns correct duration for five_days' do
            expect(AccountConfigs.parse_reminder_duration('five_days')).to eq(5.days)
        end

        it 'returns correct duration for six_days' do
            expect(AccountConfigs.parse_reminder_duration('six_days')).to eq(6.days)
        end

        it 'returns correct duration for seven_days' do
            expect(AccountConfigs.parse_reminder_duration('seven_days')).to eq(7.days)
        end

        it 'returns correct duration for eight_days' do
            expect(AccountConfigs.parse_reminder_duration('eight_days')).to eq(8.days)
        end

        it 'returns correct duration for fifteen_days' do
            expect(AccountConfigs.parse_reminder_duration('fifteen_days')).to eq(15.days)
        end

        it 'returns correct duration for twenty_one_days' do
            expect(AccountConfigs.parse_reminder_duration('twenty_one_days')).to eq(21.days)
        end

        it 'returns correct duration for thirty_days' do
            expect(AccountConfigs.parse_reminder_duration('thirty_days')).to eq(30.days)
        end

        it 'returns nil for blank value' do
            expect(AccountConfigs.parse_reminder_duration('')).to be_nil
            expect(AccountConfigs.parse_reminder_duration(nil)).to be_nil
        end

        it 'returns nil for "none"' do
            expect(AccountConfigs.parse_reminder_duration('none')).to be_nil
            expect(AccountConfigs.parse_reminder_duration('NONE')).to be_nil
        end

        it 'returns nil for invalid value' do
            expect(AccountConfigs.parse_reminder_duration('invalid_duration')).to be_nil
            expect(AccountConfigs.parse_reminder_duration('one_week')).to be_nil
        end
    end
end

