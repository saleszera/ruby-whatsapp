# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Context do
  describe ".deserialize" do
    it "maps from, id, forwarded, and frequently_forwarded" do
      context = described_class.deserialize(
        "from" => "16505551234",
        "id" => "wamid.HBg",
        "forwarded" => true,
        "frequently_forwarded" => false
      )

      expect(context.from).to eq("16505551234")
      expect(context.id).to eq("wamid.HBg")
      expect(context.forwarded).to be(true)
      expect(context.frequently_forwarded).to be(false)
    end

    it "maps from_user_id and from_parent_user_id when the quoted sender adopted a username" do
      context = described_class.deserialize(
        "id" => "wamid.HBg",
        "from_user_id" => "US.13491208655302741918",
        "from_parent_user_id" => "US.ENT.11815799212886844830"
      )

      expect(context.from_user_id).to eq("US.13491208655302741918")
      expect(context.from_parent_user_id).to eq("US.ENT.11815799212886844830")
      expect(context.from).to be_nil
    end

    it "leaves the BSUID fields nil when the quoted sender is identified by phone number" do
      context = described_class.deserialize("from" => "16505551234", "id" => "wamid.HBg")

      expect(context.from_user_id).to be_nil
      expect(context.from_parent_user_id).to be_nil
    end

    it "returns nil when there is no context" do
      expect(described_class.deserialize(nil)).to be_nil
    end
  end
end
