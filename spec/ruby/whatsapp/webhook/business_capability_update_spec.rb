# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::BusinessCapabilityUpdate do
  describe ".deserialize" do
    it "maps max_daily_conversation_per_phone and max_phone_numbers_per_business" do
      value = described_class.deserialize(
        "max_daily_conversation_per_phone" => 100_000,
        "max_phone_numbers_per_business" => 20
      )

      expect(value.max_daily_conversation_per_phone).to eq(100_000)
      expect(value.max_phone_numbers_per_business).to eq(20)
    end
  end
end
