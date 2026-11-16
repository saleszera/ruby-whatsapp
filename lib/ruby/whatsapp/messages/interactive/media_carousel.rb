# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      # A horizontally scrollable set of 2–10 media cards. `card_index` is assigned from
      # each card's position, so callers never pass it.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-media-carousel-messages
      class MediaCarousel < Base
        module Defaults
          MIN_CARDS_LENGTH = 2
          MAX_CARDS_LENGTH = 10
        end

        # @!attribute [rw] cards
        #   @return [Array<Hash>]
        attr_accessor :cards

        validates :cards, presence: true, length: { minimum: Defaults::MIN_CARDS_LENGTH,
                                                    maximum: Defaults::MAX_CARDS_LENGTH, }
        validate :validate_identical_buttons

        # @param cards [Array<Hash>] The media cards (see {Card#initialize}, without `card_index`).
        # @raise [ActiveModel::ValidationError] if validation fails, including a card's own.
        def initialize(cards:)
          @cards = cards

          validate!
        end

        class << self
          # @return [Hash] Serialized representation of the MediaCarousel.
          def serialize(cards:)
            new(cards:).serialize
          end
        end

        # @return [Hash] Serialized representation of the MediaCarousel.
        def serialize
          {
            cards: serialized_cards,
          }
        end

      private

        # @return [Array<Hash>] Serialized cards.
        def serialized_cards
          built_cards.map(&:serialize)
        end

        # @return [Array<Card>]
        # @raise [ActiveModel::ValidationError] if a card is invalid.
        def built_cards
          Array(cards).map.with_index { |card, index| Card.new(card_index: index, **card) }
        end

        # Meta: "button types and counts must match across all cards".
        # @return [void]
        def validate_identical_buttons
          return if Array(cards).size < Defaults::MIN_CARDS_LENGTH
          return if built_cards.map(&:signature).uniq.size == 1

          errors.add(:cards, "must all use the same button type and count")
        end
      end
    end
  end
end
