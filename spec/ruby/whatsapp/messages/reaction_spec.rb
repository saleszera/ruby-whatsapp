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

    # Meta: "Unicode escape sequence of the emoji, or the emoji itself" — one emoji.
    # See https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/reaction-messages
    describe "emoji" do
      [
        ["a skin-toned emoji", "👍🏽"],
        ["a ZWJ family sequence", "👨‍👩‍👧"],
        ["a flag", "🇧🇷"],
        ["a keycap", "1️⃣"],
        ["a variation-selected symbol", "❤️"],
        ["the escape-sequence form", "\u{1F600}"],
        ["a text-default symbol with its emoji variation selector", "\u00A9\uFE0F"],
        ["a subdivision flag tag sequence", "\u{1F3F4}\u{E0067}\u{E0062}\u{E0065}\u{E006E}\u{E0067}\u{E007F}"],
      ].each do |label, emoji|
        it "accepts #{label}" do
          expect { described_class.new(to:, message_id:, emoji:) }.not_to raise_error
        end
      end

      [
        ["text containing an emoji", "hello 👍"],
        ["two emoji", "👍👍"],
        ["a bare digit followed by a letter", "a1"],
        ["a bare digit", "1"],
        ["a bare #", "#"],
        ["plain text", "ok"],
        # Extended_Pictographic also covers symbols that are not emoji, and code points Unicode
        # reserves for future emoji; neither has the Emoji property.
        ["a pictographic symbol that is not an emoji", "\u2388"],
        ["a pictographic code point that is not an emoji", "\u{1F000}"],
        ["a non-emoji symbol joined to an emoji", "\u2388\u200D\u{1F44D}"],
      ].each do |label, emoji|
        it "rejects #{label}" do
          expect { described_class.new(to:, message_id:, emoji:) }
            .to raise_error(ActiveModel::ValidationError, /Emoji must be a single emoji/)
        end
      end
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
