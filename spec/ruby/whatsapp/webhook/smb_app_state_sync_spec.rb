# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::SmbAppStateSync do
  describe ".deserialize" do
    # Meta's published payload. The contact shape used to be an untyped hash, because the
    # docs described this field in one line; the BSUID docs publish it.
    # See https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids#smb_app_state_sync-webhooks
    let(:payload) do
      {
        "messaging_product" => "whatsapp",
        "metadata" => { "display_phone_number" => "15550783881", "phone_number_id" => "106540352242922" },
        "state_sync" => [
          {
            "type" => "contact",
            "contact" => {
              "full_name" => "Pablo Morales",
              "first_name" => "Pablo",
              "phone_number" => "16505551234",
              "user_id" => "US.13491208655302741918",
              "parent_user_id" => "US.ENT.11815799212886844830",
              "username" => "pablomorales",
            },
            "action" => "add",
            "metadata" => { "timestamp" => "1750030073" },
          },
        ],
      }
    end

    it "maps messaging_product and metadata" do
      value = described_class.deserialize(payload)

      expect(value.messaging_product).to eq("whatsapp")
      expect(value.metadata).to be_a(Whatsapp::Webhook::Metadata)
      expect(value.metadata.phone_number_id).to eq("106540352242922")
    end

    it "maps a state_sync entry and flattens its timestamp up from the entry metadata" do
      entry = described_class.deserialize(payload).state_sync.first

      expect(entry).to be_a(Whatsapp::Webhook::SmbAppStateSync::StateSync)
      expect(entry.type).to eq("contact")
      expect(entry.action).to eq("add")
      expect(entry.timestamp).to eq("1750030073")
    end

    it "types the synced contact, BSUID identifiers included" do
      contact = described_class.deserialize(payload).state_sync.first.contact

      expect(contact).to be_a(Whatsapp::Webhook::SmbAppStateSync::Contact)
      expect(contact.full_name).to eq("Pablo Morales")
      expect(contact.first_name).to eq("Pablo")
      expect(contact.phone_number).to eq("16505551234")
      expect(contact.user_id).to eq("US.13491208655302741918")
      expect(contact.parent_user_id).to eq("US.ENT.11815799212886844830")
      expect(contact.username).to eq("pablomorales")
    end

    it "tolerates a missing state_sync array" do
      value = described_class.deserialize({})

      expect(value.state_sync).to eq([])
      expect(value.metadata).to be_nil
    end

    it "leaves the contact nil when the entry carries none" do
      entry = described_class.deserialize("state_sync" => [{ "type" => "contact", "action" => "remove" }])
        .state_sync.first

      expect(entry.contact).to be_nil
      expect(entry.timestamp).to be_nil
    end

    it "keeps the untouched value hash, not a copy" do
      expect(described_class.deserialize(payload).raw).to equal(payload)
    end

    it "leaves raw an empty hash for a nil value" do
      expect(described_class.deserialize(nil).raw).to eq({})
    end
  end
end
