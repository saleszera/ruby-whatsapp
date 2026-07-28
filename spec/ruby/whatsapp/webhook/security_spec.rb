# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Security do
  describe ".deserialize" do
    it "maps display_phone_number, event, and requester" do
      value = described_class.deserialize(
        "display_phone_number" => "15550783881",
        "event" => "TWO_STEP_VERIFICATION_ENABLED",
        "requester" => "16505551234"
      )

      expect(value.display_phone_number).to eq("15550783881")
      expect(value.event).to eq("TWO_STEP_VERIFICATION_ENABLED")
      expect(value.requester).to eq("16505551234")
    end
  end
end
