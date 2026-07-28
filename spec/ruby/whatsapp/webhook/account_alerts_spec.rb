# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::AccountAlerts do
  describe ".deserialize" do
    it "maps entity_type, entity_id, alert_severity, alert_status, and alert_description" do
      value = described_class.deserialize(
        "entity_type" => "WABA",
        "entity_id" => "102290129340398",
        "alert_severity" => "INFO",
        "alert_status" => "ACTIVE",
        "alert_description" => "Messaging limit increased"
      )

      expect(value.entity_type).to eq("WABA")
      expect(value.entity_id).to eq("102290129340398")
      expect(value.alert_severity).to eq("INFO")
      expect(value.alert_status).to eq("ACTIVE")
      expect(value.alert_description).to eq("Messaging limit increased")
    end
  end
end
