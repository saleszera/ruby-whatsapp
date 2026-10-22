# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Interactive do
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

    # Meta requires sections[].title only once a list has more than one section.
    it "serializes a single-section list without a section title" do
      msg = described_class.new(
        to: "+1", type: :list_buttons, body: "Choose a drink",
        action: { button: "Menu", sections: [{ rows: [{ id: "espresso", title: "Espresso" }] }] }
      )

      expect(msg.serialize[:interactive][:action])
        .to eq(button: "Menu", sections: [{ rows: [{ id: "espresso", title: "Espresso" }] }])
    end

    it "rejects an untitled section in a multi-section list when serialized" do
      msg = described_class.new(
        to: "+1", type: :list_buttons, body: "Choose a drink",
        action: {
          button: "Menu",
          sections: [
            { title: "Coffee", rows: [{ id: "espresso", title: "Espresso" }] },
            { rows: [{ id: "water", title: "Water" }] },
          ],
        }
      )

      expect { msg.serialize }
        .to raise_error(ActiveModel::ValidationError, /Sections must each have a title/)
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
