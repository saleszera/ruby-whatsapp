# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::AccountReviewUpdate do
  describe ".deserialize" do
    it "maps decision" do
      value = described_class.deserialize("decision" => "APPROVED")

      expect(value.decision).to eq("APPROVED")
    end
  end
end
