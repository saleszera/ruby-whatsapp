# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Revoke do
  describe ".deserialize" do
    it "maps the revoked message's id alongside the shared envelope" do
      message = described_class.deserialize(
        "from" => "16505551234",
        "from_user_id" => "US.13491208655302741918",
        "from_parent_user_id" => "US.ENT.11815799212886844830",
        "id" => "wamid.HBg",
        "timestamp" => "1749416383",
        "type" => "revoke",
        "revoke" => { "original_message_id" => "wamid.ORIGINAL" }
      )

      expect(message.original_message_id).to eq("wamid.ORIGINAL")
      expect(message.from).to eq("16505551234")
      expect(message.from_user_id).to eq("US.13491208655302741918")
      expect(message.from_parent_user_id).to eq("US.ENT.11815799212886844830")
      expect(message.id).to eq("wamid.HBg")
      expect(message.timestamp).to eq("1749416383")
      expect(message.type).to eq("revoke")
    end

    it "identifies a username-adopted sender by BSUID alone" do
      message = described_class.deserialize(
        "from_user_id" => "US.13491208655302741918",
        "id" => "wamid.HBg",
        "timestamp" => "1749416383",
        "type" => "revoke",
        "revoke" => { "original_message_id" => "wamid.ORIGINAL" }
      )

      expect(message.from).to be_nil
      expect(message.from_user_id).to eq("US.13491208655302741918")
    end

    it "tolerates a missing revoke object" do
      message = described_class.deserialize("id" => "wamid.HBg", "timestamp" => "1", "type" => "revoke")

      expect(message.original_message_id).to be_nil
    end
  end
end
