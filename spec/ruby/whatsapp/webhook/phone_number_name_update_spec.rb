# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::PhoneNumberNameUpdate do
  describe ".deserialize" do
    it "maps phone_number, decision, requested_verified_name, and rejection_reason" do
      value = described_class.deserialize(
        "phone_number" => "15550783881",
        "decision" => "REJECTED",
        "requested_verified_name" => "Acme Corp",
        "rejection_reason" => "INCLUDES_UNSUPPORTED_CHARACTERS"
      )

      expect(value.phone_number).to eq("15550783881")
      expect(value.decision).to eq("REJECTED")
      expect(value.requested_verified_name).to eq("Acme Corp")
      expect(value.rejection_reason).to eq("INCLUDES_UNSUPPORTED_CHARACTERS")
    end
  end
end
