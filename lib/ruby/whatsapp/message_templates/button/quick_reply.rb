# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class Button
      # A tappable label that sends its own text back as a reply.
      #
      # The most common use is an opt-out ("Unsubscribe from Promos"), which Meta
      # expects on marketing templates. Up to 10 per template, but they must be
      # grouped contiguously — see {Component::Buttons}.
      # Source: https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/components/
      class QuickReply < Base
        module Defaults
          TYPE = "QUICK_REPLY"
        end

        # @!attribute [rw] text
        #   @return [String]
        attr_accessor :text

        validates :text, presence: true, length: { maximum: MAX_TEXT_LENGTH }

        # @param text [String] The button label (max 25 characters).
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(text:)
          @text = text

          validate!
        end

        # @return [Hash] The serialized button.
        def serialize
          { type: Defaults::TYPE, text: }
        end
      end
    end
  end
end
