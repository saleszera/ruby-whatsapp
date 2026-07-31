# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Contacts::Phone do
  describe ".deserialize" do
    it "maps phone, type, and wa_id" do
      phone = described_class.deserialize("phone" => "+15550001111", "type" => "WORK", "wa_id" => "15550001111")

      expect(phone.phone).to eq("+15550001111")
      expect(phone.type).to eq("WORK")
      expect(phone.wa_id).to eq("15550001111")
    end
  end
end
