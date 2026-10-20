# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class Button
      # Asks the recipient to share their phone number, which they hand over with one tap.
      #
      # The counterpart to Meta's usernames rollout: once a user adopts a username their
      # phone number may stop reaching you, leaving only their
      # [BSUID](https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids).
      # This is how you ask for the number back — and it is the only way to reach such a
      # user with a one-tap, zero-tap, or copy-code authentication template, since those
      # require a phone number.
      #
      # A tap arrives as an inbound `contacts` message whose
      # {Whatsapp::Webhook::Message::Contacts::Contact#origin} is `"contact_request"`.
      #
      # Allowed on `UTILITY` and `MARKETING` templates only — a cross-component rule, so it
      # lives in {ComponentSet} rather than here.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
      class RequestContactInfo < Base
        module Defaults
          TYPE = "REQUEST_CONTACT_INFO"
          # The only label Meta accepts, if you send one at all. What the recipient sees is
          # rendered in their own app language, so the button cannot be customized.
          TEXT = "Share Contact Info"
        end

        # @!attribute [rw] text
        #   @return [String, nil] Optional, and only ever {Defaults::TEXT}.
        attr_accessor :text

        validate :validate_text

        # @param text [String, nil] Omit it — the label is not customizable and Meta
        #   localizes what the recipient sees. Accepted only as the exact literal
        #   {Defaults::TEXT}, for callers mirroring Meta's own example payload; it is
        #   forwarded rather than dropped, since Meta documents the field as accepted.
        #  @raise [ActiveModel::ValidationError] if `text` is anything else.
        def initialize(text: nil)
          @text = text

          validate!
        end

        # @return [Hash] The serialized button — type alone, unless a label was given.
        def serialize
          { type: Defaults::TYPE, text: }.compact
        end

      private

        # Hand-rolled rather than an `inclusion:` validator, because the default message
        # ("is not included in the list") would not tell anyone *why* one value is allowed.
        # @return [void]
        def validate_text
          return if text.nil? || text == Defaults::TEXT

          errors.add(:text,
            "must be exactly #{Defaults::TEXT.inspect} if given; " \
              "Meta localizes the label the recipient sees, so it cannot be customized")
        end
      end
    end
  end
end
