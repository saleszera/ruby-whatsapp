# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::PaymentConfigurationUpdate do
  describe ".deserialize" do
    it "maps configuration_name, provider_name, provider_mid, and status" do
      value = described_class.deserialize(
        "configuration_name" => "default",
        "provider_name" => "razorpay",
        "provider_mid" => "mid.1",
        "status" => "ACTIVE"
      )

      expect(value.configuration_name).to eq("default")
      expect(value.provider_name).to eq("razorpay")
      expect(value.provider_mid).to eq("mid.1")
      expect(value.status).to eq("ACTIVE")
    end
  end
end
