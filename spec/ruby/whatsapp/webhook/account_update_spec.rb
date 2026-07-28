# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::AccountUpdate do
  describe ".deserialize" do
    it "maps phone_number, event, and ban_info" do
      value = described_class.deserialize(
        "phone_number" => "15550783881",
        "event" => "DISABLED_UPDATE",
        "ban_info" => { "waba_ban_state" => "DISABLE", "waba_ban_date" => "2024-01-01" }
      )

      expect(value.phone_number).to eq("15550783881")
      expect(value.event).to eq("DISABLED_UPDATE")
      expect(value.ban_info).to be_a(Whatsapp::Webhook::AccountUpdate::BanInfo)
      expect(value.ban_info.waba_ban_state).to eq("DISABLE")
      expect(value.ban_info.waba_ban_date).to eq("2024-01-01")
    end

    it "tolerates a missing ban_info" do
      value = described_class.deserialize("event" => "VERIFIED_ACCOUNT")

      expect(value.ban_info).to be_nil
    end
  end
end
