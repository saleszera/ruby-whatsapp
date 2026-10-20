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

    it "maps username, user_id, and parent_user_id when the user has adopted a username" do
      contact = described_class.deserialize(
        "profile" => { "name" => "test user name", "username" => "@testusername" },
        "wa_id" => "16315551181",
        "user_id" => "US.13491208655302741918",
        "parent_user_id" => "US.ENT.11815799212886844830"
      )

      expect(contact.username).to eq("@testusername")
      expect(contact.user_id).to eq("US.13491208655302741918")
      expect(contact.parent_user_id).to eq("US.ENT.11815799212886844830")
    end

    it "tolerates a missing wa_id when the user's phone number is unavailable" do
      contact = described_class.deserialize(
        "profile" => { "name" => "test user name", "username" => "@testusername" },
        "user_id" => "US.13491208655302741918"
      )

      expect(contact.wa_id).to be_nil
      expect(contact.user_id).to eq("US.13491208655302741918")
    end

    it "reads a top-level username when it is not nested under profile" do
      contact = described_class.deserialize(
        "profile" => { "name" => "test user name" },
        "username" => "@testusername",
        "user_id" => "US.13491208655302741918"
      )

      expect(contact.username).to eq("@testusername")
    end

    it "prefers the nested profile.username when both locations are present" do
      contact = described_class.deserialize(
        "profile" => { "name" => "test user name", "username" => "@nested" },
        "username" => "@flat"
      )

      expect(contact.username).to eq("@nested")
    end
  end

  describe "#initialize" do
    it "builds from a BSUID-only identity, with no phone-number fields" do
      contact = described_class.new(user_id: "US.13491208655302741918")

      expect(contact.user_id).to eq("US.13491208655302741918")
      expect(contact.profile_name).to be_nil
      expect(contact.username).to be_nil
      expect(contact.wa_id).to be_nil
      expect(contact.parent_user_id).to be_nil
    end
  end
end
