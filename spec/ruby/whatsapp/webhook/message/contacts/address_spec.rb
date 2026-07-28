# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Contacts::Address do
  describe ".deserialize" do
    it "maps every address field" do
      address = described_class.deserialize(
        "street" => "1 Hacker Way", "city" => "Menlo Park", "state" => "CA", "zip" => "94025",
        "country" => "United States", "country_code" => "US", "type" => "WORK"
      )

      expect(address.street).to eq("1 Hacker Way")
      expect(address.city).to eq("Menlo Park")
      expect(address.state).to eq("CA")
      expect(address.zip).to eq("94025")
      expect(address.country).to eq("United States")
      expect(address.country_code).to eq("US")
      expect(address.type).to eq("WORK")
    end
  end
end
