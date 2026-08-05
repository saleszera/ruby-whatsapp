# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class Button
      # Places a phone call to the business when tapped.
      #
      # At most one per template. Meta may strip leading zeros that follow the country
      # code, so store the number in full international form.
      # Source: https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/components/
      class PhoneNumber < Base
        module Defaults
          TYPE = "PHONE_NUMBER"
          MAX_PHONE_NUMBER_LENGTH = 20
        end

        # @!attribute [rw] text
        #   @return [String]
        attr_accessor :text

        # @!attribute [rw] phone_number
        #   @return [String]
        attr_accessor :phone_number

        validates :text, presence: true, length: { maximum: MAX_TEXT_LENGTH }
        validates :phone_number, presence: true, length: { maximum: Defaults::MAX_PHONE_NUMBER_LENGTH }

        # @param text [String] The button label (max 25 characters).
        # @param phone_number [String] The number to call (max 20 characters).
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(text:, phone_number:)
          @text = text
          @phone_number = phone_number

          validate!
        end

        # @return [Hash] The serialized button.
        def serialize
          { type: Defaults::TYPE, text:, phone_number: }
        end
      end
    end
  end
end
