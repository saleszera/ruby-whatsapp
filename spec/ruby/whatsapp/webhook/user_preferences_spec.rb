# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::UserPreferences do
  describe ".deserialize" do
    # Meta's published payload for this field. Before the BSUID docs shipped one, this
    # class read `wa_id`/`detail`/`value`/`timestamp` off the top of `value` — one level
    # too high — so every accessor was permanently nil. Entries are nested under a repeat
    # of the field's own name, the same convention `UserIdUpdate` already follows.
    # See https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids#user_preferences-webhooks
    let(:payload) do
      {
        "messaging_product" => "whatsapp",
        "metadata" => { "display_phone_number" => "15550783881", "phone_number_id" => "106540352242922" },
        "contacts" => [
          { "profile" => { "name" => "Pablo M.", "username" => "pablomorales" },
            "wa_id" => "16505551234",
            "user_id" => "US.13491208655302741918",
            "parent_user_id" => "US.ENT.11815799212886844830", },
        ],
        "user_preferences" => [
          { "wa_id" => "16505551234",
            "user_id" => "US.13491208655302741918",
            "parent_user_id" => "US.ENT.11815799212886844830",
            "detail" => "User requested to stop marketing messages",
            "category" => "marketing_messages",
            "value" => "stop",
            "timestamp" => 1_750_030_073, },
        ],
      }
    end

    it "maps messaging_product, metadata, contacts, and the preference entries" do
      value = described_class.deserialize(payload)

      expect(value.messaging_product).to eq("whatsapp")
      expect(value.metadata).to be_a(Whatsapp::Webhook::Metadata)
      expect(value.metadata.phone_number_id).to eq("106540352242922")
      expect(value.contacts.first).to be_a(Whatsapp::Webhook::Contact)
      expect(value.contacts.first.username).to eq("pablomorales")
      expect(value.contacts.first.user_id).to eq("US.13491208655302741918")
      expect(value.preferences.first).to be_a(Whatsapp::Webhook::UserPreferences::Entry)
    end

    it "maps every field on a preference entry" do
      entry = described_class.deserialize(payload).preferences.first

      expect(entry.wa_id).to eq("16505551234")
      expect(entry.user_id).to eq("US.13491208655302741918")
      expect(entry.parent_user_id).to eq("US.ENT.11815799212886844830")
      expect(entry.detail).to eq("User requested to stop marketing messages")
      expect(entry.category).to eq("marketing_messages")
      expect(entry.value).to eq("stop")
      expect(entry.timestamp).to eq(1_750_030_073)
    end

    it "identifies a username-adopted user by BSUID when no phone number is shared" do
      value = described_class.deserialize(
        "messaging_product" => "whatsapp",
        "contacts" => [
          { "profile" => { "name" => "Pablo M.", "username" => "pablomorales" },
            "user_id" => "US.13491208655302741918", },
        ],
        "user_preferences" => [
          { "user_id" => "US.13491208655302741918", "category" => "marketing_messages",
            "value" => "stop", "timestamp" => 1_750_030_073, },
        ]
      )

      expect(value.contacts.first.wa_id).to be_nil
      expect(value.preferences.first.wa_id).to be_nil
      expect(value.preferences.first.user_id).to eq("US.13491208655302741918")
    end

    it "tolerates a missing metadata, contacts, and user_preferences" do
      value = described_class.deserialize("messaging_product" => "whatsapp")

      expect(value.metadata).to be_nil
      expect(value.contacts).to eq([])
      expect(value.preferences).to eq([])
    end

    it "keeps the untouched value hash, not a copy" do
      expect(described_class.deserialize(payload).raw).to equal(payload)
    end

    it "keeps the raw value hash when the entries arrive under a key it does not read" do
      value = described_class.deserialize(
        "messaging_product" => "whatsapp",
        "user_preference" => [{ "wa_id" => "16505551234" }]
      )

      expect(value.preferences).to eq([])
      expect(value.raw).to eq(
        "messaging_product" => "whatsapp",
        "user_preference" => [{ "wa_id" => "16505551234" }]
      )
    end

    it "leaves raw an empty hash for a nil value" do
      expect(described_class.deserialize(nil).raw).to eq({})
    end
  end
end
