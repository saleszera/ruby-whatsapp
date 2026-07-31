# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::SmbAppStateSync do
  describe ".deserialize" do
    it "maps state_sync entries" do
      value = described_class.deserialize(
        "state_sync" => [
          { "type" => "contact", "action" => "add",
            "contact" => { "full_name" => "Jane Doe", "phone_number" => "+1" }, },
        ]
      )

      entry = value.state_sync.first

      expect(entry).to be_a(Whatsapp::Webhook::SmbAppStateSync::StateSync)
      expect(entry.type).to eq("contact")
      expect(entry.action).to eq("add")
      expect(entry.contact).to eq({ "full_name" => "Jane Doe", "phone_number" => "+1" })
    end

    it "tolerates a missing state_sync array" do
      value = described_class.deserialize({})

      expect(value.state_sync).to eq([])
    end
  end
end
