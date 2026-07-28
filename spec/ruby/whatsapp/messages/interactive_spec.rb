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
  end

  describe "validation" do
    it "raises for an unknown action type" do
      expect { described_class.new(type: :nope, **common) }
        .to raise_error(ActiveModel::ValidationError)
    end

    it "requires a recipient" do
      expect { described_class.new(type: :reply_buttons, body: "x", action: {}) }
        .to raise_error(ArgumentError, /missing keyword: :?to/)
    end
  end
end
