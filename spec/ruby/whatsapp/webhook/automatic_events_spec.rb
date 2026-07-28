# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::AutomaticEvents do
  describe ".deserialize" do
    it "maps event_type, message_id, and event_data" do
      value = described_class.deserialize(
        "event_type" => "purchase",
        "message_id" => "wamid.HBg",
        "event_data" => { "value" => 19.99, "currency" => "USD" }
      )

      expect(value.event_type).to eq("purchase")
      expect(value.message_id).to eq("wamid.HBg")
      expect(value.event_data).to eq({ "value" => 19.99, "currency" => "USD" })
    end

    it "tolerates a missing event_data" do
      value = described_class.deserialize("event_type" => "lead")

      expect(value.event_data).to eq({})
    end
  end
end
