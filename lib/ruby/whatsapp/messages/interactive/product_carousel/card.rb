# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      class ProductCarousel
        # One product card, referencing a product in a Meta catalog.
        # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-product-carousel-messages
        class Card
          include ActiveModel::Validations

          module Defaults
            TYPE = "product"
            MIN_CARD_INDEX = 0
            MAX_CARD_INDEX = 9
          end

          # @!attribute [rw] card_index
          #   @return [Integer] The card's zero-based position, assigned by {ProductCarousel}.
          attr_accessor :card_index

          # @!attribute [rw] catalog_id
          #   @return [String]
          attr_accessor :catalog_id

          # @!attribute [rw] product_retailer_id
          #   @return [String]
          attr_accessor :product_retailer_id

          validates :card_index, presence: true, numericality: {
            only_integer: true, greater_than_or_equal_to: Defaults::MIN_CARD_INDEX,
            less_than_or_equal_to: Defaults::MAX_CARD_INDEX,
          }
          validates :catalog_id, presence: true
          validates :product_retailer_id, presence: true

          # @param card_index [Integer] The card's zero-based position.
          # @param catalog_id [String] The ID of the catalog containing the product.
          # @param product_retailer_id [String] The product's retailer ID in that catalog.
          # @raise [ActiveModel::ValidationError] if validation fails.
          def initialize(card_index:, catalog_id:, product_retailer_id:)
            @card_index = card_index
            @catalog_id = catalog_id
            @product_retailer_id = product_retailer_id

            validate!
          end

          class << self
            # @return [Hash] Serialized representation of the Card.
            def serialize(card_index:, catalog_id:, product_retailer_id:)
              new(card_index:, catalog_id:, product_retailer_id:).serialize
            end
          end

          # @return [Hash] Serialized representation of the Card.
          def serialize
            {
              type: Defaults::TYPE,
              card_index:,
              action: {
                catalog_id:,
                product_retailer_id:,
              },
            }
          end
        end
      end
    end
  end
end
