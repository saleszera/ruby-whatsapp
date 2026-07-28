# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Reaction do
  let(:to) { "+16505551234" }
  let(:message_id) { "wamid.abc" }

  describe "validation" do
    it "is valid with an emoji" do
      expect { described_class.new(to:, message_id:, emoji: "👍") }.not_to raise_error
    end

    it "accepts an empty string (removes a reaction)" do
      expect { described_class.new(to:, message_id:, emoji: "") }.not_to raise_error
    end

    it "raises on a nil emoji instead of NoMethodError" do
      expect { described_class.new(to:, message_id:, emoji: nil) }
        .to raise_error(ActiveModel::ValidationError)
    end

    it "raises when message_id is missing" do
      expect { described_class.new(to:, message_id: nil, emoji: "👍") }
        .to raise_error(ActiveModel::ValidationError)
    end
  end

  describe "#serialize" do
    it "nests message_id and emoji under reaction" do
      serialized = described_class.new(to:, message_id:, emoji: "👍").serialize
      expect(serialized[:type]).to eq("reaction")
      expect(serialized[:reaction]).to eq(message_id:, emoji: "👍")
    end
  end
end
