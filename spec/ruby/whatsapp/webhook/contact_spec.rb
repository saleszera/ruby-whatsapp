# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Contact do
  describe ".deserialize" do
    it "maps profile.name and wa_id" do
      contact = described_class.deserialize(
        "profile" => { "name" => "Sheena Nelson" },
        "wa_id" => "16505551234"
      )

      expect(contact.profile_name).to eq("Sheena Nelson")
      expect(contact.wa_id).to eq("16505551234")
    end

    it "tolerates a missing profile" do
      contact = described_class.deserialize("wa_id" => "16505551234")

      expect(contact.profile_name).to be_nil
      expect(contact.wa_id).to eq("16505551234")
    end
  end
end
