# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Contacts::Url do
  describe ".deserialize" do
    it "maps url and type" do
      url = described_class.deserialize("url" => "https://example.com", "type" => "WEBSITE")

      expect(url.url).to eq("https://example.com")
      expect(url.type).to eq("WEBSITE")
    end
  end
end
