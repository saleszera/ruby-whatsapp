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

    it "validates each card on construction, as the carousel's own error" do
      expect { described_class.new(cards: [card, card.merge(product_retailer_id: "")]) }
        .to raise_error(ActiveModel::ValidationError) { |error|
          expect(error.model).to be_a(described_class)
          expect(error.message).to match(/Cards contain an invalid card at index 1: Product retailer can't be blank/)
        }
    end

    it "reports a card missing a key instead of raising ArgumentError" do
      expect { described_class.new(cards: [card, card.except(:product_retailer_id)]) }
        .to raise_error(ActiveModel::ValidationError, /Cards contain an invalid card at index 1/)
    end

    it "reports cards that are not Hashes instead of raising NoMethodError" do
      expect { described_class.new(cards: [nil, nil]) }
        .to raise_error(ActiveModel::ValidationError, /index 0.*index 1/)
    end

    it "returns false from valid? when a card has become invalid, rather than raising" do
      carousel = described_class.new(cards: [card, card])
      carousel.cards = [card, nil]

      expect(carousel.valid?).to be(false)
      expect(carousel.errors[:cards]).to include(/invalid card at index 1/)
    end

    it "keeps a malformed card a validation error through Interactive" do
      expect do
        Whatsapp::Messages::Interactive.new(to: "+1", type: :product_carousel, body: "Pick one",
          action: { cards: [nil, nil] })
      end.to raise_error(ActiveModel::ValidationError, /Action is invalid/)
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
