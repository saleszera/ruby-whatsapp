# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class Component
      # A horizontally scrollable set of 2 to 10 cards, each with its own media header
      # and buttons. Marketing templates only, which {Template} enforces.
      #
      # The card count is fixed at creation: an approved carousel template must be sent
      # with exactly the number of cards it was created with.
      #
      # Every card must share the same structure — same header format, same button
      # types, and body text either on all of them or none. Meta's stated reason for
      # the body rule is keeping card heights consistent. {Card#signature} is what makes
      # this checkable.
      # Source: https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/carousel-templates
      class Carousel < Base
        module Defaults
          TYPE = "CAROUSEL"
          MIN_CARDS = 2
          MAX_CARDS = 10
        end

        # @!attribute [rw] cards
        #   @return [Array<Carousel::Card>]
        attr_accessor :cards

        validates :cards, presence: true,
          length: { minimum: Defaults::MIN_CARDS, maximum: Defaults::MAX_CARDS }
        validate :validate_identical_structure

        # @param cards [Array<Hash, Carousel::Card>] Between 2 and 10 cards.
        # @param kwargs [Hash] Forwarded to {Base} (`parameter_format`).
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(cards: [], **)
          super(**)

          @cards = build_cards(cards)

          validate!
        end

        # @return [Hash] The serialized component.
        def serialize
          { type: Defaults::TYPE, cards: cards.map(&:serialize) }
        end

      private

        # @return [Array<Carousel::Card>]
        # @raise [ActiveModel::ValidationError] if a card is invalid.
        def build_cards(list)
          Array(list).map do |card|
            card.is_a?(Card) ? card : Card.new(**card, parameter_format:)
          end
        end

        # @return [void]
        def validate_identical_structure
          return if cards.size < 2

          signatures = cards.map(&:signature).uniq
          return if signatures.size == 1

          errors.add(:cards, "must all have an identical structure: same header format, same button types, " \
            "and body text on either every card or none")
        end
      end
    end
  end
end
