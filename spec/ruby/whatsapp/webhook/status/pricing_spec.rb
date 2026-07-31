# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Status::Pricing do
  describe ".deserialize" do
    it "maps billable, pricing_model, and category" do
      pricing = described_class.deserialize("billable" => true, "pricing_model" => "CBP", "category" => "service")

      expect(pricing.billable).to be(true)
      expect(pricing.pricing_model).to eq("CBP")
      expect(pricing.category).to eq("service")
    end
  end
end
