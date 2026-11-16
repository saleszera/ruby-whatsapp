# frozen_string_literal: true

# Every rule below is taken from Meta's product carousel reference.
# See https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-product-carousel-messages
RSpec.describe Whatsapp::Messages::Interactive::ProductCarousel do
  let(:card) { { catalog_id: "123456789", product_retailer_id: "abc123xyz" } }

  describe "#serialize" do
    it "serializes each card as a product card with card_index from position" do
      result = described_class.new(cards: [card, card.merge(product_retailer_id: "def456")]).serialize

      expect(result).to eq(
        cards: [
          { type: "product", card_index: 0, action: { catalog_id: "123456789", product_retailer_id: "abc123xyz" } },
          { type: "product", card_index: 1, action: { catalog_id: "123456789", product_retailer_id: "def456" } },
        ]
      )
    end
  end

  describe "validation" do
    it "requires between 2 and 10 cards" do
      expect { described_class.new(cards: [card]) }.to raise_error(ActiveModel::ValidationError)
      expect { described_class.new(cards: [card] * 11) }.to raise_error(ActiveModel::ValidationError)
      expect { described_class.new(cards: [card] * 10) }.not_to raise_error
    end

    it "requires every card to use the same catalog" do
      expect { described_class.new(cards: [card, card.merge(catalog_id: "987654321")]) }
        .to raise_error(ActiveModel::ValidationError, /Cards must all use the same catalog_id/)
    end
  end

  describe Whatsapp::Messages::Interactive::ProductCarousel::Card do
    it "requires a catalog_id and a product_retailer_id" do
      expect { described_class.new(card_index: 0, catalog_id: nil, product_retailer_id: "") }
        .to raise_error(ActiveModel::ValidationError, /Catalog can't be blank, Product retailer can't be blank/)
    end

    it "requires a card_index between 0 and 9" do
      expect { described_class.new(card_index: 10, **card) }
        .to raise_error(ActiveModel::ValidationError, /Card index/)
    end
  end
end
