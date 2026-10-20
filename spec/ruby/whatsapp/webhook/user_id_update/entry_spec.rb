# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::UserIdUpdate::Entry do
  describe ".deserialize" do
    it "maps wa_id, detail, user_id, parent_user_id, and timestamp" do
      entry = described_class.deserialize(
        "wa_id" => "16505551234",
        "detail" => "User id for Jane Doe has been updated.",
        "user_id" => { "previous" => "US.OLD", "current" => "US.NEW" },
        "parent_user_id" => { "previous" => "US.ENT.OLD", "current" => "US.ENT.NEW" },
        "timestamp" => "1750030073"
      )

      expect(entry.wa_id).to eq("16505551234")
      expect(entry.detail).to eq("User id for Jane Doe has been updated.")
      expect(entry.user_id).to be_a(Whatsapp::Webhook::UserIdUpdate::IdChange)
      expect(entry.user_id.previous).to eq("US.OLD")
      expect(entry.user_id.current).to eq("US.NEW")
      expect(entry.parent_user_id).to be_a(Whatsapp::Webhook::UserIdUpdate::IdChange)
      expect(entry.parent_user_id.previous).to eq("US.ENT.OLD")
      expect(entry.parent_user_id.current).to eq("US.ENT.NEW")
      expect(entry.timestamp).to eq("1750030073")
    end

    it "tolerates a missing parent_user_id" do
      entry = described_class.deserialize(
        "wa_id" => "16505551234",
        "user_id" => { "previous" => "US.OLD", "current" => "US.NEW" }
      )

      expect(entry.parent_user_id).to be_nil
    end

    it "leaves both id changes nil when the entry omits them" do
      entry = described_class.deserialize("wa_id" => "16505551234", "timestamp" => "1750030073")

      expect(entry.user_id).to be_nil
      expect(entry.parent_user_id).to be_nil
    end
  end

  describe "#initialize" do
    it "builds an entry carrying only a timestamp" do
      entry = described_class.new(timestamp: "1750030073")

      expect(entry.timestamp).to eq("1750030073")
      expect(entry.wa_id).to be_nil
      expect(entry.detail).to be_nil
      expect(entry.user_id).to be_nil
      expect(entry.parent_user_id).to be_nil
    end
  end
end
