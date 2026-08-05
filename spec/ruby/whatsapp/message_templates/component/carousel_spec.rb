# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Component::Carousel do
  let(:card) do
    {
      header: { format: "IMAGE", header_handle: "4::aW" },
      buttons: [{ type: :quick_reply, text: "More" }],
    }
  end

  describe "#serialize" do
    it "wraps the cards under a CAROUSEL component" do
      result = described_class.new(cards: [card, card]).serialize

      expect(result[:type]).to eq("CAROUSEL")
      expect(result[:cards].size).to eq(2)
      expect(result[:cards].first).to eq(
        components: [
          { type: "HEADER", format: "IMAGE", example: { header_handle: ["4::aW"] } },
          { type: "BUTTONS", buttons: [{ type: "QUICK_REPLY", text: "More" }] },
        ]
      )
    end

    it "accepts already-built card objects" do
      built = Whatsapp::MessageTemplates::Component::Carousel::Card.new(**card)

      expect(described_class.new(cards: [built, built]).serialize[:cards].size).to eq(2)
    end
  end

  describe "card count validations" do
    it "rejects a single card" do
      expect { described_class.new(cards: [card]) }
        .to raise_error(ActiveModel::ValidationError, /Cards is too short/)
    end

    it "accepts 2 cards" do
      expect { described_class.new(cards: [card, card]) }.not_to raise_error
    end

    it "accepts 10 cards" do
      expect { described_class.new(cards: Array.new(10) { card }) }.not_to raise_error
    end

    it "rejects 11 cards" do
      expect { described_class.new(cards: Array.new(11) { card }) }
        .to raise_error(ActiveModel::ValidationError, /Cards is too long/)
    end
  end

  describe "identical structure rule" do
    it "rejects cards where only some have body text" do
      with_body = card.merge(body: { text: "Great value" })

      expect { described_class.new(cards: [card, with_body]) }
        .to raise_error(ActiveModel::ValidationError, /identical/)
    end

    it "rejects cards with differing header formats" do
      video = card.merge(header: { format: "VIDEO", header_handle: "4::aW" })

      expect { described_class.new(cards: [card, video]) }
        .to raise_error(ActiveModel::ValidationError, /identical/)
    end

    it "rejects cards with differing button types" do
      other = card.merge(buttons: [{ type: :url, text: "Go", url: "https://x.test" }])

      expect { described_class.new(cards: [card, other]) }
        .to raise_error(ActiveModel::ValidationError, /identical/)
    end

    it "accepts cards that share a structure but differ in content" do
      other = {
        header: { format: "IMAGE", header_handle: "4::different" },
        buttons: [{ type: :quick_reply, text: "Less" }],
      }

      expect { described_class.new(cards: [card, other]) }.not_to raise_error
    end
  end
end
