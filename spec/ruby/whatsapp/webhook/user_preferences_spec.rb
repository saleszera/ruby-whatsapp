# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::UserPreferences do
  describe ".deserialize" do
    it "maps wa_id, detail, value, and timestamp" do
      value = described_class.deserialize(
        "wa_id" => "16505551234",
        "detail" => "stopped marketing messages",
        "value" => "stop",
        "timestamp" => "1750263773"
      )

      expect(value.wa_id).to eq("16505551234")
      expect(value.detail).to eq("stopped marketing messages")
      expect(value.value).to eq("stop")
      expect(value.timestamp).to eq("1750263773")
    end
  end
end
