# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::SmbAppStateSync::Contact do
  describe ".deserialize" do
    it "maps every documented field" do
      contact = described_class.deserialize(
        "full_name" => "Pablo Morales",
        "first_name" => "Pablo",
        "phone_number" => "16505551234",
        "user_id" => "US.13491208655302741918",
        "parent_user_id" => "US.ENT.11815799212886844830",
        "username" => "pablomorales"
      )

      expect(contact.full_name).to eq("Pablo Morales")
      expect(contact.first_name).to eq("Pablo")
      expect(contact.phone_number).to eq("16505551234")
      expect(contact.user_id).to eq("US.13491208655302741918")
      expect(contact.parent_user_id).to eq("US.ENT.11815799212886844830")
      expect(contact.username).to eq("pablomorales")
    end

    it "leaves the phone number nil for a username-adopted contact" do
      contact = described_class.deserialize(
        "full_name" => "Pablo Morales", "user_id" => "US.13491208655302741918", "username" => "pablomorales"
      )

      expect(contact.phone_number).to be_nil
      expect(contact.user_id).to eq("US.13491208655302741918")
    end

    # Unlike Webhook::Contact, whose username hides under `profile`, this one is flat.
    it "reads a flat username, not a nested profile one" do
      contact = described_class.deserialize("profile" => { "username" => "ignored" }, "username" => "pablomorales")

      expect(contact.username).to eq("pablomorales")
    end

    it "tolerates a nil contact" do
      contact = described_class.deserialize(nil)

      expect(contact.full_name).to be_nil
      expect(contact.user_id).to be_nil
    end
  end
end
