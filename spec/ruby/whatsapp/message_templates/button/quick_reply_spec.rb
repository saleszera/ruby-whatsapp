# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Button::QuickReply do
  describe "#serialize" do
    it "emits the uppercase wire type and the label" do
      expect(described_class.new(text: "Unsubscribe from Promos").serialize)
        .to eq(type: "QUICK_REPLY", text: "Unsubscribe from Promos")
    end
  end

  describe "validations" do
    it "requires text" do
      expect { described_class.new(text: nil) }
        .to raise_error(ActiveModel::ValidationError, /Text can't be blank/)
    end

    it "accepts text at the 25 character limit" do
      expect { described_class.new(text: "a" * 25) }.not_to raise_error
    end

    it "rejects text over 25 characters" do
      expect { described_class.new(text: "a" * 26) }
        .to raise_error(ActiveModel::ValidationError, /Text is too long/)
    end
  end

  describe ".serialize" do
    it "exposes a class-level shorthand" do
      expect(described_class.serialize(text: "Stop")).to eq(type: "QUICK_REPLY", text: "Stop")
    end
  end
end
