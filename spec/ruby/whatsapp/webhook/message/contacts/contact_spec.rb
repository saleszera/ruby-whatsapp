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

    it "maps vcard and origin when the card was shared via a REQUEST_CONTACT_INFO button" do
      contact = described_class.deserialize(
        "name" => { "first_name" => "Jane", "last_name" => "Doe", "formatted_name" => "Jane Doe" },
        "phones" => [{ "phone" => "12185551765", "wa_id" => "12185551765", "type" => "MOBILE" }],
        "vcard" => nil,
        "origin" => "contact_request"
      )

      expect(contact.vcard).to be_nil
      expect(contact.origin).to eq("contact_request")
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
