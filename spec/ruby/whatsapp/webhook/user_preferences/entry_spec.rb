# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::UserPreferences::Entry do
  describe ".deserialize" do
    it "maps every documented field" do
      entry = described_class.deserialize(
        "wa_id" => "16505551234",
        "user_id" => "US.13491208655302741918",
        "parent_user_id" => "US.ENT.11815799212886844830",
        "detail" => "User requested to stop marketing messages",
        "category" => "marketing_messages",
        "value" => "stop",
        "timestamp" => 1_750_030_073
      )

      expect(entry.wa_id).to eq("16505551234")
      expect(entry.user_id).to eq("US.13491208655302741918")
      expect(entry.parent_user_id).to eq("US.ENT.11815799212886844830")
      expect(entry.detail).to eq("User requested to stop marketing messages")
      expect(entry.category).to eq("marketing_messages")
      expect(entry.value).to eq("stop")
      expect(entry.timestamp).to eq(1_750_030_073)
    end

    it "leaves the phone number nil for a user identified only by BSUID" do
      entry = described_class.deserialize(
        "user_id" => "US.13491208655302741918", "value" => "resume", "timestamp" => 1_750_030_073
      )

      expect(entry.wa_id).to be_nil
      expect(entry.parent_user_id).to be_nil
      expect(entry.user_id).to eq("US.13491208655302741918")
      expect(entry.value).to eq("resume")
    end

    it "tolerates a nil entry" do
      entry = described_class.deserialize(nil)

      expect(entry.wa_id).to be_nil
      expect(entry.category).to be_nil
      expect(entry.value).to be_nil
    end
  end
end
