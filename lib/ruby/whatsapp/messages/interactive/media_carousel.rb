# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
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

        # @param cards [Array<Hash>] The media cards.
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
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def serialized_cards
          cards.map.with_index { |card, index| Card.serialize(card_index: index, **card) }
        end
      end
    end
  end
end
