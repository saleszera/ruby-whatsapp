# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class Component
      # The container for a template's tappable buttons. At most one per template,
      # holding up to 10 buttons.
      #
      # Note the asymmetry with the send side: here every button lives inside this one
      # component, whereas sending a template emits one `button` component per button,
      # addressed by a zero-based `index` that follows the order declared here. That is
      # why {#serialize} preserves the caller's order exactly.
      # Source: https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/components/
      class Buttons < Base
        module Defaults
          TYPE = "BUTTONS"
          MAX_BUTTONS = 10
        end

        # Documented per-type caps. Only the limits Meta actually publishes are
        # enforced; OTP is deliberately uncapped here (the overall MAX_BUTTONS still
        # applies) because no per-type limit is stated for it.
        MAX_PER_TYPE = {
          Button::QuickReply::Defaults::TYPE => 10,
          Button::Url::Defaults::TYPE => 2,
          Button::PhoneNumber::Defaults::TYPE => 1,
          Button::CopyCode::Defaults::TYPE => 1,
        }.freeze

        # @!attribute [rw] buttons
        #   @return [Array<Button::Base>]
        attr_accessor :buttons

        validates :buttons, presence: true, length: { maximum: Defaults::MAX_BUTTONS }
        validate :validate_per_type_caps
        validate :validate_quick_reply_grouping

        # @param buttons [Array<Hash, Button::Base>] The buttons, in display order.
        # @param kwargs [Hash] Forwarded to {Base} (`parameter_format`).
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(buttons: [], **)
          super(**)

          @buttons = build_buttons(buttons)

          validate!
        end

        # The wire types in declared order. Exposed so {Carousel} can compare card
        # structures and {Template} can inspect buttons across components.
        # @return [Array<String>]
        def api_types
          buttons.map(&:api_type)
        end

        # @return [Hash] The serialized component.
        def serialize
          { type: Defaults::TYPE, buttons: buttons.map(&:serialize) }
        end

      private

        # @return [Array<Button::Base>]
        # @raise [ActiveModel::ValidationError] if a button is invalid.
        # @raise [TemplateError] if a button type is unknown.
        def build_buttons(list)
          Array(list).map { |button| button.is_a?(Button::Base) ? button : Button.build(**button) }
        end

        # @return [void]
        def validate_per_type_caps
          api_types.tally.each do |type, count|
            maximum = MAX_PER_TYPE[type]
            next if maximum.nil? || count <= maximum

            errors.add(:buttons, "allow at most #{maximum} #{type} #{maximum == 1 ? 'button' : 'buttons'}")
          end
        end

        # Meta rejects a payload whose quick-reply buttons are interrupted by another
        # type: `[QR, URL, QR]` is invalid while `[QR, QR, URL]` and `[URL, QR, QR]`
        # are both fine. The check is therefore "do their indexes form one unbroken
        # run", not "are they first or last".
        # @return [void]
        def validate_quick_reply_grouping
          indexes = api_types.each_index.select { |i| api_types[i] == Button::QuickReply::Defaults::TYPE }
          return if indexes.size <= 1
          return if indexes.last - indexes.first == indexes.size - 1

          errors.add(:buttons, "quick reply buttons must be grouped together, without other types between them")
        end
      end
    end
  end
end
