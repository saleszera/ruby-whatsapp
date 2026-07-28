# frozen_string_literal: true

module Whatsapp
  class Messages
    class Template
      # Language code for template messages
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/supported-languages
      class Language
        include ActiveModel::Validations

        # @!attribute [rw] code
        #   @return [String]
        attr_accessor :code

        validate :validate_language_code

        # @param code [String] The language code (e.g., "en_US", "pt_BR").
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(code:)
          @code = code

          validate!
        end

        # Serializes the language to a hash format suitable for the WhatsApp API.
        # @return [Hash] The serialized language.
        def serialize
          {
            code:,
          }
        end

        class << self
          # Serializes the language to a hash format suitable for the WhatsApp API.
          # @param code [String] The language code.
          # @return [Hash] The serialized language.
          def serialize(code:)
            new(code:).serialize
          end
        end

      private

        # Validates that the language code is supported by WhatsApp
        # @return [void]
        def validate_language_code
          return if Utils::LanguageCodes.valid?(code)

          errors.add(:code,
            "is not a valid WhatsApp language code. Supported codes: #{Utils::LanguageCodes.all.join(', ')}")
        end
      end
    end
  end
end
