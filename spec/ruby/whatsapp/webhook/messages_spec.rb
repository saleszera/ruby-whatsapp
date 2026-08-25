# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Messages do
  describe ".deserialize" do
    it "maps messaging_product, metadata, contacts, and messages" do
      value = described_class.deserialize(
        "messaging_product" => "whatsapp",
        "metadata" => { "display_phone_number" => "15550783881", "phone_number_id" => "106540352242922" },
        "contacts" => [{ "profile" => { "name" => "Sheena Nelson" }, "wa_id" => "16505551234" }],
        "messages" => [
          { "from" => "16505551234", "id" => "wamid.HBg", "timestamp" => "1749416383", "type" => "text",
            "text" => { "body" => "Does it come in another color?" }, },
        ]
      )

      expect(value.messaging_product).to eq("whatsapp")
      expect(value.metadata).to be_a(Whatsapp::Webhook::Metadata)
      expect(value.metadata.phone_number_id).to eq("106540352242922")
      expect(value.contacts.first).to be_a(Whatsapp::Webhook::Contact)
      expect(value.contacts.first.wa_id).to eq("16505551234")
      expect(value.messages.first).to be_a(Whatsapp::Webhook::Message::Text)
      expect(value.messages.first.body).to eq("Does it come in another color?")
      expect(value.statuses).to eq([])
    end

    it "maps statuses" do
      value = described_class.deserialize(
        "messaging_product" => "whatsapp",
        "statuses" => [{ "id" => "wamid.HBg", "status" => "delivered", "recipient_id" => "16505551234" }]
      )

      expect(value.statuses.first).to be_a(Whatsapp::Webhook::Status)
      expect(value.statuses.first.status).to eq("delivered")
      expect(value.contacts).to eq([])
      expect(value.messages).to eq([])
    end

    # The following examples reproduce, verbatim, the payloads Meta's App Dashboard
    # webhook-testing tool sends for each Business-scoped user ID (BSUID) scenario.
    # See https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids#webhook-testing

    it "maps an incoming text message from a user who has not adopted a username" do
      value = described_class.deserialize(
        "messaging_product" => "whatsapp",
        "metadata" => { "display_phone_number" => "16505551111", "phone_number_id" => "123456123" },
        "contacts" => [
          { "profile" => { "name" => "test user name" }, "wa_id" => "16315551181",
            "user_id" => "US.13491208655302741918", },
        ],
        "messages" => [
          { "id" => "ABGGFlA5Fpa", "timestamp" => "1504902988", "from" => "16315551181",
            "from_user_id" => "US.13491208655302741918", "type" => "text",
            "text" => { "body" => "this is a text message" }, },
        ]
      )

      expect(value.contacts.first.wa_id).to eq("16315551181")
      expect(value.contacts.first.user_id).to eq("US.13491208655302741918")
      expect(value.contacts.first.username).to be_nil
      expect(value.messages.first.from).to eq("16315551181")
      expect(value.messages.first.from_user_id).to eq("US.13491208655302741918")
    end

    it "maps an incoming text message from a username-adopted user whose phone number is unavailable" do
      value = described_class.deserialize(
        "messaging_product" => "whatsapp",
        "metadata" => { "display_phone_number" => "16505551111", "phone_number_id" => "123456123" },
        "contacts" => [
          { "profile" => { "name" => "test user name", "username" => "@testusername" },
            "user_id" => "US.13491208655302741918", },
        ],
        "messages" => [
          { "id" => "ABGGFlA5Fpa", "timestamp" => "1504902988", "from_user_id" => "US.13491208655302741918",
            "type" => "text", "text" => { "body" => "this is a text message" }, },
        ]
      )

      expect(value.contacts.first.wa_id).to be_nil
      expect(value.contacts.first.username).to eq("@testusername")
      expect(value.messages.first.from).to be_nil
      expect(value.messages.first.from_user_id).to eq("US.13491208655302741918")
    end

    it "maps an incoming text message from a username-adopted user whose phone number is available" do
      value = described_class.deserialize(
        "messaging_product" => "whatsapp",
        "metadata" => { "display_phone_number" => "16505551111", "phone_number_id" => "123456123" },
        "contacts" => [
          { "profile" => { "name" => "test user name", "username" => "@testusername" },
            "wa_id" => "16315551181", "user_id" => "US.13491208655302741918", },
        ],
        "messages" => [
          { "id" => "ABGGFlA5Fpa", "timestamp" => "1504902988", "from" => "16315551181",
            "from_user_id" => "US.13491208655302741918", "type" => "text",
            "text" => { "body" => "this is a text message" }, },
        ]
      )

      expect(value.contacts.first.wa_id).to eq("16315551181")
      expect(value.contacts.first.username).to eq("@testusername")
      expect(value.messages.first.from).to eq("16315551181")
    end

    it "maps a sent status for a message addressed to a phone number, opted-in phone available" do
      value = described_class.deserialize(
        "messaging_product" => "whatsapp",
        "metadata" => { "display_phone_number" => "16505551111", "phone_number_id" => "123456123" },
        "statuses" => [
          { "id" => "ABGGFlA5Fpa", "status" => "sent", "timestamp" => "1504902988",
            "recipient_id" => "16315551181", },
        ],
        "contacts" => [
          { "profile" => { "name" => "test user name" }, "wa_id" => "16315551181",
            "user_id" => "US.13491208655302741918", },
        ]
      )

      expect(value.statuses.first.recipient_id).to eq("16315551181")
      expect(value.statuses.first.recipient_user_id).to be_nil
      expect(value.contacts.first.wa_id).to eq("16315551181")
    end

    it "maps a sent status for a message addressed to a BSUID, opted-in phone available" do
      value = described_class.deserialize(
        "messaging_product" => "whatsapp",
        "metadata" => { "display_phone_number" => "16505551111", "phone_number_id" => "123456123" },
        "statuses" => [
          { "id" => "ABGGFlA5Fpa", "status" => "sent", "timestamp" => "1504902988",
            "recipient_user_id" => "US.13491208655302741918", },
        ],
        "contacts" => [
          { "profile" => { "name" => "test user name" }, "wa_id" => "16315551181",
            "user_id" => "US.13491208655302741918", },
        ]
      )

      expect(value.statuses.first.recipient_id).to be_nil
      expect(value.statuses.first.recipient_user_id).to eq("US.13491208655302741918")
      expect(value.contacts.first.wa_id).to eq("16315551181")
    end

    it "maps a sent status for a message addressed to a phone number, opted-in phone unavailable" do
      value = described_class.deserialize(
        "messaging_product" => "whatsapp",
        "metadata" => { "display_phone_number" => "16505551111", "phone_number_id" => "123456123" },
        "statuses" => [
          { "id" => "ABGGFlA5Fpa", "status" => "sent", "timestamp" => "1504902988",
            "recipient_id" => "16315551181", },
        ],
        "contacts" => [
          { "profile" => { "name" => "test user name" }, "user_id" => "US.13491208655302741918" },
        ]
      )

      expect(value.statuses.first.recipient_id).to eq("16315551181")
      expect(value.contacts.first.wa_id).to be_nil
      expect(value.contacts.first.user_id).to eq("US.13491208655302741918")
    end

    it "maps a sent status for a message addressed to a BSUID, opted-in phone unavailable" do
      value = described_class.deserialize(
        "messaging_product" => "whatsapp",
        "metadata" => { "display_phone_number" => "16505551111", "phone_number_id" => "123456123" },
        "statuses" => [
          { "id" => "ABGGFlA5Fpa", "status" => "sent", "timestamp" => "1504902988",
            "recipient_user_id" => "US.13491208655302741918", },
        ],
        "contacts" => [
          { "profile" => { "name" => "test user name" }, "user_id" => "US.13491208655302741918" },
        ]
      )

      expect(value.statuses.first.recipient_id).to be_nil
      expect(value.statuses.first.recipient_user_id).to eq("US.13491208655302741918")
      expect(value.contacts.first.wa_id).to be_nil
    end
  end
end
