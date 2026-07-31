# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Order::ProductItem do
  describe ".deserialize" do
    it "maps product_retailer_id, quantity, item_price, and currency" do
      item = described_class.deserialize(
        "product_retailer_id" => "sku.1", "quantity" => 2, "item_price" => 9.99, "currency" => "USD"
      )

      expect(item.product_retailer_id).to eq("sku.1")
      expect(item.quantity).to eq(2)
      expect(item.item_price).to eq(9.99)
      expect(item.currency).to eq("USD")
    end
  end
end
