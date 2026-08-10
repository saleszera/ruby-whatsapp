# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    # Resolves a component kind to its implementing class.
    #
    # Resolution goes through the frozen {TYPES} whitelist — never `const_get` on
    # caller input — so an unknown or hostile `type` can only raise, never resolve an
    # arbitrary constant. Mirrors {Whatsapp::Messages::KINDS} and {Button::TYPES}.
    #
    # Only the component types with a published schema are registered. Meta's Graph API
    # enum also lists GREETING, ALBUM, CALL_PERMISSION_REQUEST, TAP_TARGET_CONFIGURATION
    # and ATTACHMENT, but publishes no field reference for them, so they are
    # deliberately absent rather than guessed.
    #
    # Note that a component validates only *itself* here. Rules that span components —
    # a footer being forbidden alongside a limited-time offer, a carousel implying the
    # MARKETING category — live on {Template}, which is the only object that can see
    # all the siblings.
    # Source: https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/components/
    class Component
      TYPES = {
        header: Header,
        body: Body,
        footer: Footer,
        buttons: Buttons,
        carousel: Carousel,
        limited_time_offer: LimitedTimeOffer,
      }.freeze

      class << self
        # @param type [Symbol, String] The component kind, in either casing
        #   (`:body`, `"body"`, or Meta's `"BODY"`).
        # @param attrs [Hash] Forwarded to the resolved component class, including the
        #   owning template's `parameter_format`.
        # @return [Component::Base]
        # @raise [TemplateError] if the type is unknown.
        # @raise [ActiveModel::ValidationError] if the component is invalid.
        def build(type:, **attrs)
          klass = TYPES.fetch(normalize(type)) do
            raise TemplateError,
              "Unknown component type: #{type.inspect}. Known types: #{TYPES.keys.join(', ')}"
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
