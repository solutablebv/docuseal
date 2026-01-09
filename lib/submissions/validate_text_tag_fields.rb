# frozen_string_literal: true

module Submissions
  module ValidateTextTagFields
    InvalidFieldError = Class.new(StandardError)

    SUPPORTED_FIELD_TYPES = %w[
      text signature initials date datenow image file payment stamp
      select checkbox multiple radio phone verification kba
    ].freeze

    module_function

    def call(fields, submitter_roles)
      fields.each do |field|
        validate_field(field, submitter_roles)
      end
    end

    private

    module_function

    def validate_field(field, submitter_roles)
      # Validate name
      raise InvalidFieldError, 'Field name is required' if field['name'].blank?

      # Validate type
      field_type = field['type']
      unless SUPPORTED_FIELD_TYPES.include?(field_type)
        raise InvalidFieldError, "Unsupported field type: #{field_type}"
      end

      # Validate areas
      raise InvalidFieldError, 'Field must have at least one area' if field['areas'].blank?

      field['areas'].each do |area|
        validate_area(area, field_type)
      end

      # Validate submitter role if specified
      if field['_role'].present?
        role = field['_role']
        unless submitter_roles.any? { |s| (s['name'] || s['role']).to_s.casecmp(role.to_s).zero? }
          raise InvalidFieldError, "Invalid role '#{role}' for field '#{field['name']}'"
        end
      end

      # Validate options for select/radio/multiple
      if %w[select radio multiple].include?(field_type)
        if field['options'].blank? || field['options'].empty?
          raise InvalidFieldError, "Field type '#{field_type}' requires options"
        end
      end

      # Validate conditions
      if field['conditions'].present?
        field['conditions'].each do |condition|
          validate_condition(condition)
        end
      end

      # Validate date format
      if field_type == 'date' && field.dig('preferences', 'format').present?
        format = field['preferences']['format']
        unless format.match?(%r{[myd]{2,4}[-\\/\s.][myd]{2,4}[-\\/\s.][myd]{2,4}}i)
          raise InvalidFieldError, "Invalid date format: #{format}"
        end
      end

      # Validate min/max
      if field['validation'].present?
        min = field['validation']['min']
        max = field['validation']['max']
        if min.present? && max.present? && min > max
          raise InvalidFieldError, "Validation min (#{min}) cannot be greater than max (#{max})"
        end
      end
    end

    def validate_area(area, field_type)
      %w[x y w h page].each do |key|
        raise InvalidFieldError, "Area missing required key: #{key}" unless area.key?(key)
      end

      # Validate coordinate ranges (normalized 0-1)
      %w[x y w h].each do |key|
        value = area[key]
        if value.nil? || value < 0 || value > 1
          raise InvalidFieldError, "Area #{key} must be between 0 and 1 (normalized), got: #{value}"
        end
      end

      # Validate page number (0-based for array indexing)
      page = area['page']
      unless page.is_a?(Integer) && page >= 0
        raise InvalidFieldError, "Area page must be a non-negative integer (0-based), got: #{page}"
      end

      # Validate attachment_uuid
      raise InvalidFieldError, 'Area missing attachment_uuid' if area['attachment_uuid'].blank?
    end

    def validate_condition(condition)
      %w[action operation].each do |key|
        raise InvalidFieldError, "Condition missing required key: #{key}" unless condition.key?(key)
      end

      valid_actions = %w[show hide]
      unless valid_actions.include?(condition['action'])
        raise InvalidFieldError, "Invalid condition action: #{condition['action']}"
      end

      valid_operations = %w[equals not_equals contains not_contains empty not_empty]
      unless valid_operations.include?(condition['operation'])
        raise InvalidFieldError, "Invalid condition operation: #{condition['operation']}"
      end
    end
  end
end
