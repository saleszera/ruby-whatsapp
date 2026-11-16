# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      class MediaCarousel
        # One swipeable card: a media header, an optional short body, and either one
        # URL button or one or more quick-reply buttons, both carried in the card's
        # `action`.
        # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-media-carousel-messages
        class Card
          include ActiveModel::Validations

          module Defaults
            # Meta uses this card type for URL-button and quick-reply cards alike.
            TYPE = "cta_url"
            MIN_CARD_INDEX = 0
            MAX_CARD_INDEX = 9
            MAX_BODY_LENGTH = 160
            MAX_BODY_LINE_BREAKS = 2
            HEADER_TYPES = [Header::Types::IMAGE, Header::Types::VIDEO].freeze
          end

          # @!attribute [rw] card_index
          #   @return [Integer] The card's zero-based position, assigned by {MediaCarousel}.
          attr_accessor :card_index

          # @!attribute [rw] header
          #   @return [Hash] An image or video header, in {Interactive::Header}'s shape.
          attr_accessor :header

          # @!attribute [rw] body
          #   @return [String, nil]
          attr_accessor :body

          # @!attribute [rw] action
          #   @return [Hash, nil] A URL button, in {Interactive::UrlButton}'s shape.
          attr_accessor :action

          # @!attribute [rw] buttons
          #   @return [Array<Hash>, nil] Quick-reply buttons, each `{ quick_reply: { id:, title: } }`.
          attr_accessor :buttons

          validates :card_index, presence: true, numericality: {
            only_integer: true, greater_than_or_equal_to: Defaults::MIN_CARD_INDEX,
            less_than_or_equal_to: Defaults::MAX_CARD_INDEX,
          }
          validates :header, presence: true
          validates :body, length: { maximum: Defaults::MAX_BODY_LENGTH }, allow_nil: true
          validate :validate_header_type
          validate :validate_body_line_breaks
          validate :validate_one_button_kind

          # @param card_index [Integer] The card's zero-based position.
          # @param header [Hash] An image or video header.
          # @param body [String, nil] Optional card text.
          # @param action [Hash, nil] A URL button (`name:`, `display_text:`, `url:`). Exclusive with `buttons`.
          # @param buttons [Array<Hash>, nil] Quick-reply buttons. Exclusive with `action`.
          # @raise [ActiveModel::ValidationError] if validation fails.
          def initialize(card_index:, header:, body: nil, action: nil, buttons: nil)
            @card_index = card_index
            @header = header
            @body = body
            @action = action
            @buttons = buttons

            validate!
          end

          class << self
            # @return [Hash] Serialized representation of the Card.
            def serialize(**)
              new(**).serialize
            end
          end

          # A comparable description of the card's buttons, used by {MediaCarousel} to
          # enforce Meta's rule that every card uses the same button type and count.
          # @return [Array]
          def signature
            action.nil? ? [:quick_reply, buttons.size] : [:cta_url, 1]
          end

          # @return [Hash] Serialized representation of the Card.
          def serialize
            {
              card_index:,
              type: Defaults::TYPE,
              header: Interactive::Header.serialize(**header),
              body: body && Interactive::Body.serialize(body),
              action: serialized_action,
            }.compact
          end

        private

          # @return [Hash]
          def serialized_action
            return UrlButton.serialize(**action) unless action.nil?

            { buttons: buttons.map { |button| Button.serialize(**button) } }
          end

          # @return [void]
          def validate_header_type
            return if header.nil?
            return if header.is_a?(Hash) && Defaults::HEADER_TYPES.include?(header[:type].to_s)

            errors.add(:header, "must be an image or video")
          end

          # @return [void]
          def validate_body_line_breaks
            return if body.nil? || body.count("\n") <= Defaults::MAX_BODY_LINE_BREAKS

            errors.add(:body, "can contain at most #{Defaults::MAX_BODY_LINE_BREAKS} line breaks")
          end

          # @return [void]
          def validate_one_button_kind
            return if action.present? ^ buttons.present?

            errors.add(:base, "A card must have either a URL button action or quick-reply buttons, not both")
          end
        end
      end
    end
  end
end
