# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Base do
  describe ".common_attributes" do
    it "maps the shared envelope, including from_user_id and from_parent_user_id" do
      attributes = described_class.common_attributes(
        "from" => "16315551181",
        "from_user_id" => "US.13491208655302741918",
        "from_parent_user_id" => "US.ENT.11815799212886844830",
        "id" => "ABGGFlA5Fpa",
        "timestamp" => "1504902988",
        "type" => "text"
      )

      expect(attributes[:from]).to eq("16315551181")
      expect(attributes[:from_user_id]).to eq("US.13491208655302741918")
      expect(attributes[:from_parent_user_id]).to eq("US.ENT.11815799212886844830")
      expect(attributes[:id]).to eq("ABGGFlA5Fpa")
      expect(attributes[:timestamp]).to eq("1504902988")
      expect(attributes[:type]).to eq("text")
      expect(attributes[:context]).to be_nil
      expect(attributes[:referral]).to be_nil
    end

    it "tolerates a missing from_user_id and from_parent_user_id, e.g. when the user has not adopted BSUID" do
      attributes = described_class.common_attributes("from" => "16315551181", "type" => "text")

      expect(attributes[:from_user_id]).to be_nil
      expect(attributes[:from_parent_user_id]).to be_nil
    end

    it "threads the quoted sender's BSUID through the deserialized context" do
      attributes = described_class.common_attributes(
        "type" => "text",
        "from_user_id" => "US.13491208655302741918",
        "context" => { "id" => "wamid.HBg", "from_user_id" => "US.99999999999999999999" }
      )

      expect(attributes[:context].from_user_id).to eq("US.99999999999999999999")
    end

    it "extracts group_id, so every message type learns it came from a group" do
      attributes = described_class.common_attributes(
        "from" => "16505551234",
        "group_id" => "group.1",
        "id" => "wamid.HBg",
        "timestamp" => "1749416383",
        "type" => "text"
      )

      expect(attributes[:group_id]).to eq("group.1")
    end

    it "leaves group_id nil for a one-to-one message" do
      attributes = described_class.common_attributes(
        "from" => "16505551234", "id" => "wamid.HBg", "timestamp" => "1749416383", "type" => "text"
      )

      expect(attributes[:group_id]).to be_nil
    end
  end

  describe "#initialize" do
    it "builds a message whose sender is only a BSUID" do
      message = described_class.new(
        id: "wamid.HBg", timestamp: "1504902988", type: "text",
        from_user_id: "US.13491208655302741918"
      )

      expect(message.from_user_id).to eq("US.13491208655302741918")
      expect(message.from).to be_nil
      expect(message.from_parent_user_id).to be_nil
      expect(message.context).to be_nil
      expect(message.referral).to be_nil
    end
  end
end
