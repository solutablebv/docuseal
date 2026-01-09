# frozen_string_literal: true

module Submissions
  module ExtractTextTags
    TAG_PATTERN = /\{\{([^}]+)\}\}/
    SUPPORTED_FIELD_TYPES = %w[
      text signature initials date datenow image file payment stamp
      select checkbox multiple radio phone verification kba
    ].freeze

    module_function

    def call(pdf_data, attachment_uuid: nil)
      doc = Pdfium::Document.open_bytes(pdf_data)
      fields = []

      doc.page_count.times do |page_index|
        page = doc.get_page(page_index)
        text_nodes = page.text_nodes
        next if text_nodes.blank?

        # Build full text from nodes for position calculations
        full_text_nodes = text_nodes.map(&:content).join
        
        # Use Pdfium's text method for extracting tag content (preserves spaces in field names)
        full_text_with_spaces = page.text
        tag_matches = full_text_with_spaces.scan(TAG_PATTERN)

        next if tag_matches.blank?

        # Find tag positions in text nodes (using nodes text for accurate positions)
        # But extract tag content from spaced text for correct field names
        tag_fields = find_tags_in_text(text_nodes, full_text_nodes, full_text_with_spaces, page_index, attachment_uuid)

        fields.concat(tag_fields)
      end

      fields
    ensure
      doc&.close
    end

    def find_tags_in_text(text_nodes, full_text_nodes, full_text_with_spaces, page_index, attachment_uuid)
      fields = []

      # Find tag matches in the spaced text to get correct field names
      # But use positions from nodes text for accurate bounding box calculations
      tag_contents = []
      full_text_with_spaces.to_enum(:scan, TAG_PATTERN).each do
        match = Regexp.last_match
        tag_contents << match[1] # First capture group - the tag content with proper spacing
      end

      # Now find the same tags in the nodes text to get accurate positions
      full_text_nodes.to_enum(:scan, TAG_PATTERN).map do
        [Regexp.last_match, Regexp.last_match.begin(0), Regexp.last_match.end(0)]
      end.each_with_index do |(match, tag_start_pos, tag_end_pos), index|
        # Use the tag content from spaced text (for correct field names)
        # but positions from nodes text (for accurate bounding boxes)
        tag_content = tag_contents[index] || match[1]

        # Find corresponding text nodes for this tag using nodes text positions
        tag_nodes = find_nodes_for_range(text_nodes, tag_start_pos, tag_end_pos)

        if tag_nodes.present?
          field = parse_tag(tag_content, tag_nodes, page_index, attachment_uuid)
          fields << field if field
        end
      end

      fields
    end

    def find_nodes_for_range(text_nodes, start_pos, end_pos)
      tag_nodes = []
      char_pos = 0

      text_nodes.each do |node|
        node_length = node.content.length
        node_start = char_pos
        node_end = char_pos + node_length

        # Check if this node overlaps with the tag range
        tag_nodes << node if node_start < end_pos && node_end > start_pos

        char_pos = node_end

        # Stop if we've passed the tag end
        break if char_pos > end_pos
      end

      tag_nodes
    end

    def parse_tag(tag_content, tag_nodes, page_index, attachment_uuid)
      # Parse tag content: "Field Name;role=Signer1;type=date"
      parts = tag_content.split(';')
      field_name = parts.first&.strip

      # Parse attributes
      attrs = {}
      parts[1..].each do |part|
        key, value = part.split('=', 2).map(&:strip)
        next if key.blank?

        attrs[key] = value
      end

      # Extract field name if not in attributes
      attrs['name'] ||= field_name if field_name.present?

      # Determine field type
      field_type = attrs['type'] || 'text'
      field_type = 'date' if field_type == 'datenow'
      field_type = 'verification' if field_type == 'kba'

      # Calculate bounding box from tag nodes
      area = calculate_bounding_box(tag_nodes, page_index, attachment_uuid, field_type)
      return nil unless area

      # Build field structure
      field = {
        'uuid' => SecureRandom.uuid,
        'name' => attrs['name'] || 'Field',
        'type' => field_type,
        'required' => parse_boolean(attrs['required'], true),
        'readonly' => parse_boolean(attrs['readonly'], false),
        'submitter_uuid' => nil, # Will be set later based on role
        'areas' => [area],
        'preferences' => build_preferences(attrs, field_type),
        'default_value' => attrs['default']
      }

      # Handle datenow type
      if attrs['type'] == 'datenow'
        field['readonly'] = true
        field['default_value'] = '{{date}}'
      end

      # Handle options for select/radio/multiple
      if %w[select radio multiple].include?(field_type) && attrs['options'].present?
        options = attrs['options'].split(',').map(&:strip)
        field['options'] = options.map { |opt| { 'value' => opt, 'uuid' => SecureRandom.uuid } }
      end

      # Handle radio option
      if field_type == 'radio' && attrs['option'].present?
        field['options'] = [{ 'value' => attrs['option'], 'uuid' => SecureRandom.uuid }]
      end

      # Handle condition
      if attrs['condition'].present?
        condition_parts = attrs['condition'].split(':')
        if condition_parts.size == 2
          field['conditions'] = [{
            'field_uuid' => nil, # Will be resolved later based on field name
            'value' => condition_parts[1],
            'action' => 'show',
            'operation' => 'equals'
          }]
        elsif condition_parts.size == 1
          # Condition for non-empty field
          field['conditions'] = [{
            'field_uuid' => nil, # Will be resolved later based on field name
            'value' => nil,
            'action' => 'show',
            'operation' => 'not_empty'
          }]
        end
      end

      # Handle validation (min/max)
      if attrs['min'].present? || attrs['max'].present?
        field['validation'] = {}
        field['validation']['min'] = parse_numeric(attrs['min']) if attrs['min'].present?
        field['validation']['max'] = parse_numeric(attrs['max']) if attrs['max'].present?
      end

      # Store role for later mapping
      field['_role'] = attrs['role'] if attrs['role'].present?

      # Handle hidden field
      field['hidden'] = parse_boolean(attrs['hidden'], false)

      field
    end

    def calculate_bounding_box(tag_nodes, page_index, attachment_uuid, field_type = nil)
      return nil if tag_nodes.blank?

      # Get page dimensions from first node (assuming all nodes are on same page)
      first_node = tag_nodes.first
      return nil unless first_node

      # Calculate bounding box from all tag nodes
      min_x = tag_nodes.map(&:x).min
      max_x = tag_nodes.map { |n| n.x + n.w }.max
      min_y = tag_nodes.map(&:y).min
      max_y = tag_nodes.map { |n| n.y + n.h }.max

      width = max_x - min_x
      height = max_y - min_y

      # For signature fields, ensure minimum height of 3 lines
      # Calculate average text node height to determine line height
      # Then ensure signature is at least 3 lines tall
      if field_type == 'signature'
        avg_node_height = tag_nodes.map(&:h).sum / tag_nodes.size.to_f
        min_height = avg_node_height * 3.0
        # Also ensure absolute minimum of approximately 3/35 of page height (typical line height)
        min_height = [min_height, 3.0 / 35.0].max
        height = [height, min_height].max
      end

      {
        'x' => min_x,
        'y' => min_y,
        'w' => width,
        'h' => height,
        'page' => page_index,
        'attachment_uuid' => attachment_uuid
      }
    end

    def build_preferences(attrs, field_type)
      preferences = {}

      # Format
      preferences['format'] = attrs['format'] if attrs['format'].present?

      # Font settings
      preferences['font'] = attrs['font'] if attrs['font'].present?
      preferences['font_size'] = parse_numeric(attrs['font_size']) if attrs['font_size'].present?
      preferences['font_type'] = attrs['font_type'] if attrs['font_type'].present?

      # Color
      preferences['color'] = attrs['color'] if attrs['color'].present?

      # Alignment
      preferences['align'] = attrs['align'] if attrs['align'].present?
      preferences['valign'] = attrs['valign'] if attrs['valign'].present?

      # Dimensions (if specified)
      preferences['width'] = parse_numeric(attrs['width']) if attrs['width'].present?
      preferences['height'] = parse_numeric(attrs['height']) if attrs['height'].present?

      # Method for verification fields
      preferences['method'] = attrs['method'] if field_type == 'verification' && attrs['method'].present?

      # Mask
      preferences['mask'] = true if parse_boolean(attrs['mask'], false)

      preferences
    end

    def parse_boolean(value, default)
      return default if value.blank?

      case value.to_s.downcase
      when 'true', '1', 'yes'
        true
      when 'false', '0', 'no'
        false
      else
        default
      end
    end

    def parse_numeric(value)
      return nil if value.blank?

      # Try integer first, then float
      if value.to_s.include?('.')
        value.to_f
      else
        value.to_i
      end
    rescue StandardError
      nil
    end
  end
end
