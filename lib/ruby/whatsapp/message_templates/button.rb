# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    # Resolves a button kind to its implementing class.
    #
    # Resolution goes through the frozen {TYPES} whitelist — never `const_get` on
    # caller input — so an unknown or hostile `type` can only raise, never resolve an
    # arbitrary constant. Mirrors {Whatsapp::Messages::KINDS} and
    # {Whatsapp::Messages::Interactive::ACTION_TYPES}.
    #
    # Only the button types with a published schema are registered. Meta's Graph API
    # enum also lists FLOW, MPM, CATALOG, VOICE_CALL, VIDEO_CALL, POSTBACK,
    # BOOKING_STATUS, PAYMENT_REQUEST and REQUEST_CONTACT_INFO, but publishes no
    # field reference for them, so they are deliberately absent rather than guessed.
    # Source: https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/components/
    class Button
      TYPES = {
        quick_reply: QuickReply,
        url: Url,
        phone_number: PhoneNumber,
        copy_code: CopyCode,
        otp: Otp,
      }.freeze

      class << self
        # @param type [Symbol, String] The button kind, in either casing
        #   (`:quick_reply`, `"quick_reply"`, or Meta's `"QUICK_REPLY"`).
        # @param attrs [Hash] Forwarded to the resolved button class.
        # @return [Button::Base]
        # @raise [TemplateError] if the type is unknown.
        # @raise [ActiveModel::ValidationError] if the button is invalid.
        def build(type:, **attrs)
          klass = TYPES.fetch(normalize(type)) do
            raise TemplateError,
              "Unknown button type: #{type.inspect}. Known types: #{TYPES.keys.join(', ')}"
          end

          klass.new(**attrs)
        end

        # Builds and serializes in one step.
        # @return [Hash]
        def serialize(type:, **attrs)
          build(type:, **attrs).serialize
        end

        # @param type [Symbol, String]
        # @return [Symbol] The registry key for the given type.
        def normalize(type)
          type.to_s.downcase.to_sym
        end
      end
    end
  end
end
