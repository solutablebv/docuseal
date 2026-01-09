# frozen_string_literal: true

module Submissions
  module RemoveTextTags
    module_function

    def call(pdf_data, extracted_tags = [])
      return pdf_data if extracted_tags.blank?

      pdf = HexaPDF::Document.new(io: StringIO.new(pdf_data))

      # Group tags by page (0-based from extraction)
      tags_by_page = extracted_tags.group_by { |tag| tag['areas'].first&.dig('page') || 0 }

      pdf.pages.each_with_index do |page, page_index|
        page_tags = tags_by_page[page_index] || []
        next if page_tags.blank?

        remove_tags_from_page(page, page_tags)
      end

      output = StringIO.new
      pdf.write(output, validate: false)
      output.rewind
      output.read
    rescue StandardError => e
      Rollbar.error(e) if defined?(Rollbar)

      # If removal fails, return original PDF
      pdf_data
    end

    private

    module_function

    def remove_tags_from_page(page, page_tags)
      canvas = page.canvas(type: :overlay)
      page_width = page.box.width
      page_height = page.box.height

      # Draw white rectangles over each tag area to hide them
      page_tags.each do |tag|
        tag['areas'].each do |area|
          next if area.blank?

          # Convert normalized coordinates (0-1) to PDF points
          # PDF coordinates: origin at bottom-left, y increases upward
          # Normalized coordinates: origin at top-left, y increases downward
          x = area['x'] * page_width
          y_normalized = area['y']
          h_normalized = area['h'] || 0.01 # Default height if missing
          w_normalized = area['w'] || 0.1 # Default width if missing

          # Convert to PDF coordinates (bottom-left origin)
          pdf_y = page_height - (y_normalized * page_height) - (h_normalized * page_height)
          pdf_width = w_normalized * page_width
          pdf_height = h_normalized * page_height

          # Add small padding to ensure complete coverage
          padding = 2
          canvas.fill_color('white')
              .rectangle(x - padding, pdf_y - padding, pdf_width + (padding * 2), pdf_height + (padding * 2))
              .fill
        end
      end
    end
  end
end
