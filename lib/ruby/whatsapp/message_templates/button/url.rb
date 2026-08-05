# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class Button
      # Opens a URL in the device's default browser.
      #
      # May carry a single variable, and only appended at the very end of the URL —
      # Meta substitutes the send-side value there. Note the `example` here is a flat
      # array *on the button*, unlike the header/body `example` object built by
      # {Example}; that inconsistency is Meta's.
      # Source: https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/components/
      class Url < Base
        module Defaults
          TYPE = "URL"
          MAX_URL_LENGTH = 2000
          MAX_VARIABLES = 1
        end

        # Matches a placeholder occupying the very end of the URL.
        TRAILING_VARIABLE = /\{\{\s*\w+\s*\}\}\z/

        # @!attribute [rw] text
        #   @return [String]
        attr_accessor :text

        # @!attribute [rw] url
        #   @return [String]
        attr_accessor :url

        # @!attribute [rw] example
        #   @return [Array<String>, nil]
        attr_accessor :example

        validates :text, presence: true, length: { maximum: MAX_TEXT_LENGTH }
        validates :url, presence: true, length: { maximum: Defaults::MAX_URL_LENGTH }
        validate :validate_variable
        validate :validate_example_present

        # @param text [String] The button label (max 25 characters).
        # @param url [String] The URL (max 2000 characters), optionally ending in a
        #   single `{{1}}` or `{{name}}` placeholder.
        # @param example [String, Array<String>, nil] A sample value for the
        #   placeholder. Required when the URL has one.
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(text:, url:, example: nil)
          @text = text
          @url = url
          @example = normalize_example(example)

          validate!
        end

        # @return [Hash] The serialized button.
        def serialize
          {
            type: Defaults::TYPE,
            text:,
            url:,
            example:,
          }.compact
        end

      private

        # @return [Array<String>, nil]
        def normalize_example(value)
          return if blank_value?(value)

          value.is_a?(Array) ? value : [value]
        end

        # @return [Boolean] Whether the URL declares a placeholder.
        def variable?
          Placeholders.count(url).positive?
        end

        # A URL may carry at most one variable, and it must be the trailing segment.
        # @return [void]
        def validate_variable
          return if blank_value?(url)

          count = Placeholders.count(url)
          return if count.zero?

          if count > Defaults::MAX_VARIABLES
            errors.add(:url, "supports at most one variable, found #{count}")
            return
          end

          return if url.match?(TRAILING_VARIABLE)

          errors.add(:url, "variable must be at the end of the URL")
        end

        # @return [void]
        def validate_example_present
          return if blank_value?(url) || !variable?
          return unless blank_value?(example)

          errors.add(:example, "can't be blank when the URL contains a variable")
        end
      end
    end
  end
end
