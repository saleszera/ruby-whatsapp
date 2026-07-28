# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::PhoneNumberQualityUpdate do
  describe ".deserialize" do
    it "maps display_phone_number, event, and current_limit" do
      value = described_class.deserialize(
        "display_phone_number" => "15550783881",
        "event" => "DOWNGRADE",
        "current_limit" => "TIER_50"
      )

      expect(value.display_phone_number).to eq("15550783881")
      expect(value.event).to eq("DOWNGRADE")
      expect(value.current_limit).to eq("TIER_50")
    end
  end
end
