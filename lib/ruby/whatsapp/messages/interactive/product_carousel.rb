# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      # A horizontally scrollable set of 2–10 product cards from one catalog.
      # `card_index` is assigned from each card's position, so callers never pass it.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-product-carousel-messages
      class ProductCarousel < Base
        include CarouselCards

        module Defaults
          MIN_CARDS_COUNT = 2
          MAX_CARDS_COUNT = 10
        end

        # @!attribute [rw] cards
        #   @return [Array<Hash>]
        attr_accessor :cards

        validates :cards, presence: true, length: { minimum: Defaults::MIN_CARDS_COUNT,
                                                    maximum: Defaults::MAX_CARDS_COUNT, }
        validate :validate_cards

        # @param cards [Array<Hash>] The cards (`catalog_id:`, `product_retailer_id:`).
        # @raise [ActiveModel::ValidationError] if validation fails, including a card's own.
        def initialize(cards:)
          @cards = cards

          validate!
        end

        class << self
          # @return [Hash] Serialized representation of the ProductCarousel.
          def serialize(cards:)
            new(cards:).serialize
          end
        end

        # @return [Hash] Serialized representation of the ProductCarousel.
        def serialize
          {
            cards: serialized_cards,
          }
        end

      private

        # @return [Array<Hash>] Serialized cards.
        # @raise [ActiveModel::ValidationError] if a card is invalid.
        def serialized_cards
          cards.map.with_index { |card, index| Card.serialize(card_index: index, **card) }
        end

        # Reports each invalid card, then Meta's cross-card rule: "each card must use the
        # same catalog ID".
        # @return [void]
        def validate_cards
          built = build_cards(Card)
          return if built.nil? || built.map(&:catalog_id).uniq.size <= 1

          errors.add(:cards, "must all use the same catalog_id")
        end
      end
    end
  end
end
