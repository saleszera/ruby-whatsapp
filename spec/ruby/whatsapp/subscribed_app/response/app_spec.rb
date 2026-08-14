# frozen_string_literal: true

RSpec.describe Whatsapp::SubscribedApp::Response::App do
  describe ".deserialize" do
    it "flattens the whatsapp_business_api_data and reads the override callback uri" do
      result = described_class.deserialize(
        "whatsapp_business_api_data" => {
          "id" => "123456789", "name" => "My App", "link" => "https://www.facebook.com/games/?app_id=123456789",
        },
        "override_callback_uri" => "https://example.com/webhooks"
      )

      expect(result.id).to eq("123456789")
      expect(result.name).to eq("My App")
      expect(result.link).to eq("https://www.facebook.com/games/?app_id=123456789")
      expect(result.override_callback_uri).to eq("https://example.com/webhooks")
    end

    it "tolerates a missing whatsapp_business_api_data" do
      result = described_class.deserialize("override_callback_uri" => "https://example.com/webhooks")

      expect(result.id).to be_nil
      expect(result.name).to be_nil
      expect(result.link).to be_nil
      expect(result.override_callback_uri).to eq("https://example.com/webhooks")
    end

    it "tolerates a nil payload" do
      result = described_class.deserialize(nil)

      expect(result.id).to be_nil
      expect(result.override_callback_uri).to be_nil
    end
  end
end
