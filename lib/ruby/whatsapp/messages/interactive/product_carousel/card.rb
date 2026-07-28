# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      class ProductCarousel
        class Card
          module Defaults
            TYPE = "product"
          end

          # @!attribute [rw] card_index
          #   @return [Integer]
          attr_accessor :card_index

          # @!attribute [rw] catalog_id
          #   @return [String]
          attr_accessor :catalog_id

          # @!attribute [rw] product_retailer_id
          #   @return [String]
          attr_accessor :product_retailer_id

          # @param card_index [Integer] The index of the card in the carousel.
          # @param catalog_id [String] The catalog ID associated with the product.
          # @param product_retailer_id [String] The retailer ID of the product.
          def initialize(card_index:, catalog_id:, product_retailer_id:)
            @card_index = card_index
            @catalog_id = catalog_id
            @product_retailer_id = product_retailer_id
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
