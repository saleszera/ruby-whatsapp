# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Order do
  describe ".deserialize" do
    it "maps catalog_id, text, and product_items" do
      message = described_class.deserialize(
        "type" => "order",
        "order" => {
          "catalog_id" => "cat.1",
          "text" => "Here's my order",
          "product_items" => [
            { "product_retailer_id" => "sku.1", "quantity" => 2, "item_price" => 9.99, "currency" => "USD" },
          ],
        }
      )

      expect(message.catalog_id).to eq("cat.1")
      expect(message.text).to eq("Here's my order")
      expect(message.product_items.first).to be_a(Whatsapp::Webhook::Message::Order::ProductItem)
      expect(message.product_items.first.product_retailer_id).to eq("sku.1")
      expect(message.product_items.first.quantity).to eq(2)
    end

    it "tolerates missing product_items" do
      message = described_class.deserialize("type" => "order", "order" => { "catalog_id" => "cat.1" })

      expect(message.product_items).to eq([])
    end
  end
end
