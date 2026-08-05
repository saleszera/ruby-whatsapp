# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class Component
      # The offer banner that turns a marketing template into a limited-time offer,
      # optionally with a live countdown timer.
      #
      # Its presence changes the rules for the rest of the template: a footer becomes
      # forbidden, the body drops to 600 characters, the header narrows to image or
      # video, and the category must be MARKETING. Those are all cross-component rules,
      # so {Template} enforces them.
      #
      # The expiry timestamp itself is *not* set here — it is supplied per message when
      # sending, as `expiration_time_ms`. This component only declares that the
      # template has one.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/marketing-templates/limited-time-offer-templates
      class LimitedTimeOffer < Base
        module Defaults
          TYPE = "LIMITED_TIME_OFFER"
          MAX_TEXT_LENGTH = 16
        end

        # @!attribute [rw] text
        #   @return [String]
        attr_accessor :text

        # @!attribute [rw] has_expiration
        #   @return [Boolean, nil]
        attr_accessor :has_expiration

        validates :text, presence: true, length: { maximum: Defaults::MAX_TEXT_LENGTH }

        # @param text [String] The offer label (max 16 characters).
        # @param has_expiration [Boolean, nil] Whether to show a countdown timer.
        # @param kwargs [Hash] Forwarded to {Base} (`parameter_format`).
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(text:, has_expiration: nil, **)
          super(**)

          @text = text
          @has_expiration = has_expiration

          validate!
        end

        # @return [Hash] The serialized component.
        def serialize
          {
            type: Defaults::TYPE,
            limited_time_offer: { text:, has_expiration: }.compact,
          }
        end
      end
    end
  end
end
