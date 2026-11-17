# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      # Builds a carousel's cards during validation, so an invalid or malformed card is
      # reported on the carousel's own `:cards` errors and `valid?` returns false instead
      # of raising. Included by {MediaCarousel} and {ProductCarousel}, which expose `cards`.
      module CarouselCards
        # What building a card from caller input can raise: the card's own validation,
        # a missing or unknown keyword, or a card that is not a Hash.
        CARD_ERRORS = [ActiveModel::ValidationError, ArgumentError, TypeError].freeze

      private

        # @param card_class [Class] The card class, built with `card_index:` from position.
        # @return [Array<Object>, nil] The built cards, or nil when any card is invalid
        #   (each one is reported on `:cards`).
        def build_cards(card_class)
          built = Array(cards).each_with_index.map { |card, index| build_card(card_class, card, index) }
          built.all? ? built : nil
        end

        # @return [Object, nil] The built card, or nil after reporting why it is invalid.
        def build_card(card_class, card, index)
          card_class.new(card_index: index, **card)
        rescue *CARD_ERRORS => e
          errors.add(:cards, :invalid,
            message: "contain an invalid card at index #{index}: #{Interactive.nested_error_message(e)}")
          nil
        end
      end
    end
  end
end
