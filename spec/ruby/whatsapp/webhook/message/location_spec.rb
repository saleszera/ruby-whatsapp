# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Location do
  describe ".deserialize" do
    it "maps latitude, longitude, name, and address" do
      message = described_class.deserialize(
        "type" => "location",
        "location" => { "latitude" => 37.4847, "longitude" => -122.1477, "name" => "Meta HQ",
                        "address" => "1 Hacker Way", }
      )

      expect(message.latitude).to eq(37.4847)
      expect(message.longitude).to eq(-122.1477)
      expect(message.name).to eq("Meta HQ")
      expect(message.address).to eq("1 Hacker Way")
    end
  end
end
