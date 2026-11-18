# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::ConversationalAutomation::Limits do
  it "pins the counts and lengths Meta documents" do
    expect(described_class::PROMPTS).to eq(4)
    expect(described_class::PROMPT_LENGTH).to eq(80)
    expect(described_class::COMMANDS).to eq(30)
    expect(described_class::COMMAND_NAME_LENGTH).to eq(32)
    expect(described_class::COMMAND_DESCRIPTION_LENGTH).to eq(256)
  end

  describe ".emoji?" do
    [
      "Hi 👋",
      "Plan a trip ✈️",
      "🇧🇷 Brasil",
      "1️⃣ option",
      "❤️",
      "Family 👨‍👩‍👧",
      "Thumbs 👍🏽",
    ].each do |text|
      it "flags #{text.inspect}" do
        expect(described_class.emoji?(text)).to be(true)
      end
    end

    [
      "Book a flight",
      "© 2026 ACME",
      "Brand™",
      "Price 5 €",
      "Café ação",
      "→ next",
      "#1 choice",
      "Order 123",
    ].each do |text|
      it "lets #{text.inspect} through" do
        expect(described_class.emoji?(text)).to be(false)
      end
    end

    it "lets a pictograph in text presentation through, leaving the edge case to Meta" do
      expect(described_class.emoji?("Plan a trip ✈")).to be(false)
    end
  end
end
