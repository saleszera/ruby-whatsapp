# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      class Order < Base
        # A single line item within an inbound order message.
        class ProductItem
          # @!attribute [rw] product_retailer_id
          #   @return [String, nil] The catalog SKU.
          attr_accessor :product_retailer_id

          # @!attribute [rw] quantity
          #   @return [Integer, nil]
          attr_accessor :quantity

          # @!attribute [rw] item_price
          #   @return [Float, nil]
          attr_accessor :item_price

          # @!attribute [rw] currency
          #   @return [String, nil]
          attr_accessor :currency

          def initialize(product_retailer_id:, quantity:, item_price:, currency:)
            @product_retailer_id = product_retailer_id
            @quantity = quantity
            @item_price = item_price
            @currency = currency
          end

          class << self
            # @param data [Hash] A raw `product_items[]` entry.
            # @return [ProductItem]
            def deserialize(data)
              data ||= {}

              new(
                product_retailer_id: data["product_retailer_id"],
                quantity: data["quantity"],
                item_price: data["item_price"],
                currency: data["currency"]
              )
            end
          end
        end
      end
    end
  end
end
