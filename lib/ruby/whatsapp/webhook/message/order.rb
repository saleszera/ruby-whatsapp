# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # An inbound order placed against a Meta catalog.
      class Order < Base
        # @!attribute [rw] catalog_id
        #   @return [String, nil]
        attr_accessor :catalog_id

        # @!attribute [rw] text
        #   @return [String, nil] Optional note the customer attached to the order.
        attr_accessor :text

        # @!attribute [rw] product_items
        #   @return [Array<ProductItem>]
        attr_accessor :product_items

        def initialize(catalog_id:, product_items:, text: nil, **base_attributes)
          super(**base_attributes)

          @catalog_id = catalog_id
          @text = text
          @product_items = product_items
        end

        class << self
          # @param data [Hash] The raw message hash.
          # @return [Order]
          def deserialize(data)
            new(
              catalog_id: data.dig("order", "catalog_id"),
              text: data.dig("order", "text"),
              product_items: Array(data.dig("order", "product_items")).map { |item| ProductItem.deserialize(item) },
              **common_attributes(data)
            )
          end
        end
      end
    end
  end
end
