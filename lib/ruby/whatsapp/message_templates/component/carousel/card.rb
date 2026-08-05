# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class Component
      class Carousel
        # One card in a carousel: a required media header, an optional body, and up to
        # two buttons.
        #
        # Composes {Component::Header} and {Component::Buttons} rather than restating
        # their rules — the only extra constraint is that a card's header must be image
        # or video, since a carousel card cannot be text or a location.
        #
        # Note there is no `card_index` here. Cards are positional at creation time;
        # the zero-based `card_index` only appears when sending a message.
        # Source: https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/carousel-templates
        class Card
          include ValueObject

          module Defaults
            MAX_BUTTONS = 2
          end

          # A carousel card's header is restricted to these formats.
          ALLOWED_HEADER_FORMATS = [Header::Formats::IMAGE, Header::Formats::VIDEO].freeze

          # @!attribute [rw] header
          #   @return [Component::Header]
          attr_accessor :header

          # @!attribute [rw] body
          #   @return [Component::Body, nil]
          attr_accessor :body

          # @!attribute [rw] buttons
          #   @return [Component::Buttons, nil]
          attr_accessor :buttons

          validates :header, presence: true
          validate :validate_header_format
          validate :validate_button_count

          # @param header [Hash, Component::Header] The card's media header.
          # @param body [Hash, Component::Body, nil] The card's body.
          # @param buttons [Array<Hash, Button::Base>, nil] Up to 2 buttons.
          # @param parameter_format [String, Symbol] The owning template's placeholder
          #   style, threaded into the card's own components.
          #  @raise [ActiveModel::ValidationError] if validation fails.
          def initialize(header:, body: nil, buttons: nil, parameter_format: ParameterFormats::POSITIONAL)
            @parameter_format = ParameterFormats.normalize(parameter_format)
            @header = build(Header, header)
            @body = build(Body, body)
            @buttons = blank_value?(buttons) ? nil : Buttons.new(buttons:, parameter_format: @parameter_format)

            validate!
          end

          # A comparable description of the card's shape, used by {Carousel} to enforce
          # Meta's "all cards must have the same components" rule. Content is
          # deliberately excluded — only structure matters.
          # @return [Array]
          def signature
            [header&.format, !body.nil?, buttons&.api_types]
          end

          # @return [Hash] The serialized card.
          def serialize
            { components: [header, body, buttons].compact.map(&:serialize) }
          end

        private

          # @return [Component::Base, nil]
          def build(klass, value)
            return if blank_value?(value)
            return value if value.is_a?(klass)

            klass.new(**value, parameter_format: @parameter_format)
          end

          # @return [void]
          def validate_header_format
            return if header.nil?
            return if ALLOWED_HEADER_FORMATS.include?(header.format)

            errors.add(:header, "format must be IMAGE or VIDEO for a carousel card, got #{header.format}")
          end

          # @return [void]
          def validate_button_count
            return if buttons.nil?
            return if buttons.buttons.size <= Defaults::MAX_BUTTONS

            errors.add(:buttons, "allow at most #{Defaults::MAX_BUTTONS} buttons per carousel card")
          end
        end
      end
    end
  end
end
