# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Contacts do
  describe ".deserialize" do
    it "maps an array of contact cards" do
      message = described_class.deserialize(
        "type" => "contacts",
        "contacts" => [
          { "name" => { "formatted_name" => "Jane Doe" }, "phones" => [{ "phone" => "+1", "type" => "WORK" }] },
        ]
      )

      expect(message.contacts.first).to be_a(Whatsapp::Webhook::Message::Contacts::Contact)
      expect(message.contacts.first.name.formatted_name).to eq("Jane Doe")
      expect(message.contacts.first.phones.first.phone).to eq("+1")
    end

    it "tolerates a missing contacts array" do
      message = described_class.deserialize("type" => "contacts")

      expect(message.contacts).to eq([])
    end

    it "maps a contact shared via a REQUEST_CONTACT_INFO button from a username-adopted sender" do
      message = described_class.deserialize(
        "id" => "ABGGFlA5Fpa",
        "timestamp" => "1504902988",
        "from_user_id" => "US.13491208655302741918",
        "type" => "contacts",
        "contacts" => [
          {
            "name" => { "first_name" => "Jane", "last_name" => "Doe", "formatted_name" => "Jane Doe" },
            "phones" => [{ "phone" => "12185551765", "wa_id" => "12185551765", "type" => "MOBILE" }],
            "origin" => "contact_request",
          },
        ]
      )

      expect(message.from).to be_nil
      expect(message.from_user_id).to eq("US.13491208655302741918")
      expect(message.contacts.first.name.formatted_name).to eq("Jane Doe")
      expect(message.contacts.first.phones.first.phone).to eq("12185551765")
      expect(message.contacts.first.phones.first.wa_id).to eq("12185551765")
      expect(message.contacts.first.origin).to eq("contact_request")
      expect(message.contacts.first.vcard).to be_nil
    end
  end
end
