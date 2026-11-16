# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Interactive do
  let(:product_cards) { { cards: [{ catalog_id: "1", product_retailer_id: "a" }] * 2 } }
  let(:common) do
    { to: "+1", body: "Pick one", action: { buttons: [{ id: "a", title: "A" }] } }
  end

  describe "#serialize" do
    subject(:serialized) { described_class.new(type: :reply_buttons, **common).serialize }

    it "wraps the message as an interactive type" do
      expect(serialized[:type]).to eq("interactive")
    end

    it "emits the WhatsApp interactive type for the action kind" do
      expect(serialized[:interactive][:type]).to eq("button")
    end

    it "serializes the body as a nested text object" do
      expect(serialized[:interactive][:body]).to eq(text: "Pick one")
    end

    it "delegates action serialization to the action class" do
      buttons = serialized[:interactive][:action][:buttons]
      expect(buttons.first).to eq(type: "reply", reply: { id: "a", title: "A" })
    end

    it "serializes an optional header and footer when given" do
      msg = described_class.new(
        type: :reply_buttons,
        header: { type: "text", text: "Hi" },
        footer: { text: "bye" },
        **common
      )
      out = msg.serialize[:interactive]
      expect(out[:header]).to eq(type: "text", text: "Hi")
      expect(out[:footer]).to eq(text: "bye")
    end

    # Both carousels are `interactive.type: "carousel"`; `product_list` is a different
    # (multi-product) message.
    # See https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-product-carousel-messages
    it "emits carousel as the wire type of a product carousel" do
      msg = described_class.new(
        to: "+1", type: :product_carousel, body: "Recommended for you",
        action: product_cards
      )

      expect(msg.serialize[:interactive][:type]).to eq("carousel")
    end

    # Neither carousel supports a message-level header or footer.
    # See https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-media-carousel-messages
    it "rejects a header or footer on a carousel" do
      carousel = {
        to: "+1", type: :product_carousel, body: "Recommended for you",
        action: product_cards,
      }

      expect { described_class.new(**carousel, footer: { text: "bye" }) }
        .to raise_error(ActiveModel::ValidationError, /Footer is not supported on a product_carousel message/)
      expect { described_class.new(**carousel, header: { type: "text", text: "Hi" }) }
        .to raise_error(ActiveModel::ValidationError, /Header is not supported on a product_carousel message/)
    end

    # Meta requires sections[].title only once a list has more than one section.
    it "serializes a single-section list without a section title" do
      msg = described_class.new(
        to: "+1", type: :list_buttons, body: "Choose a drink",
        action: { button: "Menu", sections: [{ rows: [{ id: "espresso", title: "Espresso" }] }] }
      )

      expect(msg.serialize[:interactive][:action])
        .to eq(button: "Menu", sections: [{ rows: [{ id: "espresso", title: "Espresso" }] }])
    end

    # See https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-list-messages
    it "rejects an untitled section in a multi-section list on construction" do
      expect do
        described_class.new(
          to: "+1", type: :list_buttons, body: "Choose a drink",
          action: {
            button: "Menu",
            sections: [
              { title: "Coffee", rows: [{ id: "espresso", title: "Espresso" }] },
              { rows: [{ id: "water", title: "Water" }] },
            ],
          }
        )
      end.to raise_error(ActiveModel::ValidationError, /Sections must each have a title/)
    end
  end

  # Every other message kind is fully validated by the time `new` returns; the nested
  # header, body, footer and action must be too, or `valid?` reports true for a payload
  # that `serialize` (and so `send!`) would then refuse.
  describe "validation of nested parts" do
    def build(**overrides)
      described_class.new(type: :reply_buttons, **common, **overrides)
    end

    # Reply-button titles are at most 20 characters and ids are required.
    # See https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-reply-buttons-messages
    it "rejects an invalid action on construction" do
      expect { build(action: { buttons: [{ id: "", title: "" }] }) }
        .to raise_error(ActiveModel::ValidationError, /Action is invalid:/)
    end

    it "is not valid? once a nested part has become invalid" do
      message = build
      message.action = { buttons: [{ id: "a", title: "x" * 21 }] }

      expect(message).not_to be_valid
      expect(message.errors[:action].first).to include("is too long")
    end

    # Body text is at most 1024 characters.
    it "rejects a body over 1024 characters on construction" do
      expect { build(body: "x" * 1025) }
        .to raise_error(ActiveModel::ValidationError, /Body is invalid: Text is too long/)
    end

    # Footer text is at most 60 characters.
    it "rejects a footer over 60 characters on construction" do
      expect { build(footer: { text: "x" * 61 }) }
        .to raise_error(ActiveModel::ValidationError, /Footer is invalid: Text is too long/)
    end

    it "rejects an incomplete header on construction" do
      expect { build(header: { type: "text" }) }
        .to raise_error(ActiveModel::ValidationError, /Header is invalid: Text content is required/)
    end

    it "reports an unknown action keyword as a validation error, not an ArgumentError" do
      expect { build(action: { buttons: [{ id: "a", title: "A" }], colour: "red" }) }
        .to raise_error(ActiveModel::ValidationError, /Action is invalid: unknown keyword: :colour/)
    end

    it "reports a missing type as a validation error, not a NoMethodError" do
      expect { described_class.new(type: nil, **common) }
        .to raise_error(ActiveModel::ValidationError, /Type can't be blank/)
    end
  end

  describe "validation" do
    it "raises for an unknown action type" do
      expect { described_class.new(type: :nope, **common) }
        .to raise_error(ActiveModel::ValidationError)
    end

    it "requires a recipient" do
      expect { described_class.new(type: :reply_buttons, body: "x", action: {}) }
        .to raise_error(ActiveModel::ValidationError, /at least one of to or recipient/)
    end

    it "accepts a BSUID recipient in place of a phone number" do
      expect do
        described_class.new(
          recipient: "US.13491208655302741918", type: :reply_buttons, body: "x",
          action: { buttons: [{ id: "1", title: "Yes" }] }
        )
      end.not_to raise_error
    end

    describe "request_contact_info" do
      let(:message) do
        described_class.new(recipient: "US.13491208655302741918", type: :request_contact_info,
          body: "Mind sharing your number so we can text you the code?")
      end

      it "needs no action, being the one kind with nothing to supply" do
        expect { message }.not_to raise_error
      end

      it "serializes as an interactive message naming the action twice, as Meta does" do
        payload = message.serialize

        expect(payload[:type]).to eq("interactive")
        expect(payload[:recipient]).to eq("US.13491208655302741918")
        expect(payload[:interactive][:type]).to eq("request_contact_info")
        expect(payload[:interactive][:body]).to eq(text: "Mind sharing your number so we can text you the code?")
        expect(payload[:interactive][:action]).to eq(name: "request_contact_info")
      end

      it "omits the header and footer Meta's example does not show" do
        expect(message.serialize[:interactive]).not_to have_key(:header)
        expect(message.serialize[:interactive]).not_to have_key(:footer)
      end

      it "produces the same payload when the action is spelled out" do
        explicit = described_class.new(recipient: "US.13491208655302741918", type: :request_contact_info,
          body: "Mind sharing your number so we can text you the code?",
          action: { name: "request_contact_info" })

        expect(explicit.serialize).to eq(message.serialize)
      end

      it "still requires a body" do
        expect do
          described_class.new(recipient: "US.13491208655302741918", type: :request_contact_info, body: nil)
        end.to raise_error(ActiveModel::ValidationError, /Body can't be blank/)
      end
    end

    it "still requires an action for every other kind" do
      expect { described_class.new(to: "+1555", type: :reply_buttons, body: "x") }
        .to raise_error(ActiveModel::ValidationError, /Action can't be blank/)
    end

    # The action validator reads ACTION_TYPES with [] rather than fetch, so an unknown
    # type reaches the inclusion validator instead of raising KeyError from inside one.
    it "reports an unknown type as a validation error, not a KeyError" do
      expect { described_class.new(to: "+1555", type: :telepathy, body: "x") }
        .to raise_error(ActiveModel::ValidationError, /Type is not included in the list/)
    end
  end
end
