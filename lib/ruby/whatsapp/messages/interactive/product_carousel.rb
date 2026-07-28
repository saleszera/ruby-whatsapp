# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      class ProductCarousel < Base
        module Defaults
          MIN_CARDS_COUNT = 2
          MAX_CARDS_COUNT = 10
        end

        # @!attribute [rw] cards
        #   @return [Array<Hash>]
        attr_accessor :cards

        validates :cards, presence: true, length: { minimum: Defaults::MIN_CARDS_COUNT,
                                                    maximum: Defaults::MAX_CARDS_COUNT, }

        # @param cards [Array<Hash>] The cards of the product carousel.
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
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def serialized_cards
          cards.map.with_index { |card, index| Card.serialize(card_index: index, **card) }
        end
      end
    end
  end
end
