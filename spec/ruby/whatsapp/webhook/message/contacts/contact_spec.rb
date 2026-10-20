# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Contacts::Contact do
  describe ".deserialize" do
    it "maps name, phones, emails, addresses, org, urls, and birthday" do
      contact = described_class.deserialize(
        "name" => { "formatted_name" => "Jane Doe", "first_name" => "Jane" },
        "phones" => [{ "phone" => "+15550001111", "type" => "WORK" }],
        "emails" => [{ "email" => "jane@example.com", "type" => "WORK" }],
        "addresses" => [{ "city" => "Bangalore", "type" => "HOME" }],
        "org" => { "company" => "Acme Inc." },
        "urls" => [{ "url" => "https://example.com", "type" => "WEBSITE" }],
        "birthday" => "1990-05-12"
      )

      expect(contact.name.formatted_name).to eq("Jane Doe")
      expect(contact.phones.first.phone).to eq("+15550001111")
      expect(contact.emails.first.email).to eq("jane@example.com")
      expect(contact.addresses.first.city).to eq("Bangalore")
      expect(contact.org.company).to eq("Acme Inc.")
      expect(contact.urls.first.url).to eq("https://example.com")
      expect(contact.birthday).to eq("1990-05-12")
    end

    it "tolerates missing optional arrays and org" do
      contact = described_class.deserialize("name" => { "formatted_name" => "Jane Doe" })

      expect(contact.phones).to eq([])
      expect(contact.emails).to eq([])
      expect(contact.addresses).to eq([])
      expect(contact.urls).to eq([])
      expect(contact.org).to be_nil
      expect(contact.vcard).to be_nil
      expect(contact.origin).to be_nil
    end

    it "maps a REQUEST_CONTACT_INFO card: origin, split name, and a wa_id-bearing phone" do
      contact = described_class.deserialize(
        "name" => { "first_name" => "Jane", "last_name" => "Doe", "formatted_name" => "Jane Doe" },
        "phones" => [{ "phone" => "12185551765", "wa_id" => "12185551765", "type" => "MOBILE" }],
        "origin" => "contact_request"
      )

      expect(contact.origin).to eq("contact_request")
      expect(contact.name.first_name).to eq("Jane")
      expect(contact.name.last_name).to eq("Doe")
      expect(contact.phones.first.phone).to eq("12185551765")
      expect(contact.phones.first.wa_id).to eq("12185551765")
      expect(contact.phones.first.type).to eq("MOBILE")
      expect(contact.vcard).to be_nil
    end

    it "maps a non-nil vcard when the card was shared directly from the chat" do
      contact = described_class.deserialize(
        "name" => { "formatted_name" => "Jane Doe" },
        "vcard" => "BEGIN:VCARD\nEND:VCARD",
        "origin" => "other"
      )

      expect(contact.vcard).to eq("BEGIN:VCARD\nEND:VCARD")
      expect(contact.origin).to eq("other")
    end
  end
end
