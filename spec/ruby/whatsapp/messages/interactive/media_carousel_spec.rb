# frozen_string_literal: true

# Every rule below is taken from Meta's media carousel reference.
# See https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-media-carousel-messages
RSpec.describe Whatsapp::Messages::Interactive::MediaCarousel do
  let(:header) { { type: "image", link: "https://example.com/1.jpg" } }
  let(:url_card) do
    { header:, body: "Item one", action: { name: "cta_url", display_text: "Buy", url: "https://example.com/1" } }
  end
  let(:quick_reply_card) do
    { header:, body: "Item one", buttons: [{ quick_reply: { id: "q1", title: "Details" } }] }
  end

  describe "#serialize" do
    it "nests a URL button card's action under the card's action, with card_index from position" do
      result = described_class.new(cards: [url_card, url_card]).serialize

      expect(result[:cards].last).to eq(
        card_index: 1,
        type: "cta_url",
        header: { type: "image", image: { link: "https://example.com/1.jpg" } },
        body: { text: "Item one" },
        action: { name: "cta_url", parameters: { display_text: "Buy", url: "https://example.com/1" } }
      )
    end

    it "nests quick-reply buttons under the card's action, not beside it" do
      result = described_class.new(cards: [quick_reply_card, quick_reply_card]).serialize

      expect(result[:cards].first).to eq(
        card_index: 0,
        type: "cta_url",
        header: { type: "image", image: { link: "https://example.com/1.jpg" } },
        body: { text: "Item one" },
        action: { buttons: [{ type: "quick_reply", quick_reply: { id: "q1", title: "Details" } }] }
      )
    end

    it "omits the card body, which is optional" do
      card = url_card.except(:body)

      expect(described_class.new(cards: [card, card]).serialize[:cards].first).not_to have_key(:body)
    end
  end

  describe "validation" do
    it "requires between 2 and 10 cards" do
      expect { described_class.new(cards: [url_card]) }.to raise_error(ActiveModel::ValidationError)
      expect { described_class.new(cards: [url_card] * 11) }.to raise_error(ActiveModel::ValidationError)
      expect { described_class.new(cards: [url_card] * 10) }.not_to raise_error
    end

    it "requires every card to use the same kind and number of buttons" do
      two_replies = quick_reply_card.merge(buttons: quick_reply_card[:buttons] * 2)

      expect { described_class.new(cards: [url_card, quick_reply_card]) }
        .to raise_error(ActiveModel::ValidationError, /Cards must all use the same button type and count/)
      expect { described_class.new(cards: [quick_reply_card, two_replies]) }
        .to raise_error(ActiveModel::ValidationError, /Cards must all use the same button type and count/)
    end
  end

  describe Whatsapp::Messages::Interactive::MediaCarousel::Card do
    def build(**overrides)
      described_class.new(card_index: 0, **url_card, **overrides)
    end

    it "requires either a URL button action or quick-reply buttons" do
      expect { described_class.new(card_index: 0, header:, body: "x") }
        .to raise_error(ActiveModel::ValidationError, /must have either a URL button action or quick-reply buttons/)
    end

    it "rejects a URL button action and quick-reply buttons together" do
      expect { build(buttons: quick_reply_card[:buttons]) }
        .to raise_error(ActiveModel::ValidationError, /must have either a URL button action or quick-reply buttons/)
    end

    it "requires an image or video header" do
      expect { build(header: { type: "text", text: "Hi" }) }
        .to raise_error(ActiveModel::ValidationError, /Header must be an image or video/)
      expect { build(header: { type: "video", link: "https://example.com/1.mp4" }) }.not_to raise_error
    end

    it "limits the card body to 160 characters" do
      expect { build(body: "x" * 160) }.not_to raise_error
      expect { build(body: "x" * 161) }
        .to raise_error(ActiveModel::ValidationError, /Body is too long \(maximum is 160 characters\)/)
    end

    it "limits the card body to 2 line breaks" do
      expect { build(body: "a\nb\nc") }.not_to raise_error
      expect { build(body: "a\nb\nc\nd") }
        .to raise_error(ActiveModel::ValidationError, /Body can contain at most 2 line breaks/)
    end

    it "requires a card_index between 0 and 9" do
      expect { build(card_index: 10) }.to raise_error(ActiveModel::ValidationError, /Card index/)
    end
  end

  describe Whatsapp::Messages::Interactive::MediaCarousel::Card::Button::QuickReply do
    it "allows an id of up to 256 characters" do
      expect { described_class.new(id: "x" * 256, title: "Details") }.not_to raise_error
      expect { described_class.new(id: "x" * 257, title: "Details") }
        .to raise_error(ActiveModel::ValidationError, /Id is too long \(maximum is 256 characters\)/)
    end

    it "limits the title to 20 characters" do
      expect { described_class.new(id: "q1", title: "x" * 21) }
        .to raise_error(ActiveModel::ValidationError, /Title is too long \(maximum is 20 characters\)/)
    end

    it "requires an id and a title" do
      expect { described_class.new(id: "", title: "") }
        .to raise_error(ActiveModel::ValidationError, /Id can't be blank, Title can't be blank/)
    end
  end

  describe Whatsapp::Messages::Interactive::MediaCarousel::Card::Button do
    it "requires the quick_reply content" do
      expect { described_class.new(quick_reply: nil) }
        .to raise_error(ActiveModel::ValidationError, /Quick reply can't be blank/)
    end
  end
end
