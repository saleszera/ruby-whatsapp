# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::SmbMessageEchoes do
  describe ".deserialize" do
    # Meta's published payload. The BSUID docs add the value-level `contacts` array and
    # the per-echo `to`/`to_user_id`/`to_parent_user_id` recipient identifiers.
    # See https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids#smb_message_echoes-webhooks
    let(:payload) do
      {
        "messaging_product" => "whatsapp",
        "metadata" => { "display_phone_number" => "15550783881", "phone_number_id" => "106540352242922" },
        "contacts" => [
          { "profile" => { "username" => "pablomorales" },
            "wa_id" => "16505551234",
            "user_id" => "US.13491208655302741918",
            "parent_user_id" => "US.ENT.11815799212886844830", },
        ],
        "message_echoes" => [
          { "from" => "15550783881",
            "to" => "16505551234",
            "to_user_id" => "US.13491208655302741918",
            "to_parent_user_id" => "US.ENT.11815799212886844830",
            "id" => "wamid.HBg",
            "timestamp" => "1750030073",
            "type" => "text",
            "text" => { "body" => "Thanks for shopping with us!" }, },
        ],
      }
    end

    it "maps messaging_product and metadata" do
      value = described_class.deserialize(payload)

      expect(value.messaging_product).to eq("whatsapp")
      expect(value.metadata).to be_a(Whatsapp::Webhook::Metadata)
      expect(value.metadata.phone_number_id).to eq("106540352242922")
    end

    it "maps the value-level contacts, BSUID identifiers included" do
      contact = described_class.deserialize(payload).contacts.first

      expect(contact).to be_a(Whatsapp::Webhook::Contact)
      expect(contact.username).to eq("pablomorales")
      expect(contact.wa_id).to eq("16505551234")
      expect(contact.user_id).to eq("US.13491208655302741918")
      expect(contact.parent_user_id).to eq("US.ENT.11815799212886844830")
    end

    it "wraps each echo with the recipient it was sent to" do
      echo = described_class.deserialize(payload).message_echoes.first

      expect(echo).to be_a(Whatsapp::Webhook::SmbMessageEchoes::Echo)
      expect(echo.to).to eq("16505551234")
      expect(echo.to_user_id).to eq("US.13491208655302741918")
      expect(echo.to_parent_user_id).to eq("US.ENT.11815799212886844830")
    end

    it "dispatches the echoed message by its type, with from set to the business number" do
      echo = described_class.deserialize(payload).message_echoes.first

      expect(echo.message).to be_a(Whatsapp::Webhook::Message::Text)
      expect(echo.message.body).to eq("Thanks for shopping with us!")
      expect(echo.message.from).to eq("15550783881")
      expect(echo.message.id).to eq("wamid.HBg")
    end

    it "omits the recipient phone number for a username-adopted customer" do
      echo = described_class.deserialize(
        "message_echoes" => [
          { "from" => "15550783881", "to_user_id" => "US.13491208655302741918",
            "type" => "text", "text" => { "body" => "Hi" }, },
        ]
      ).message_echoes.first

      expect(echo.to).to be_nil
      expect(echo.to_user_id).to eq("US.13491208655302741918")
    end

    it "carries a revoke the business made from the WhatsApp Business app" do
      echo = described_class.deserialize(
        "message_echoes" => [
          { "from" => "15550783881", "to" => "16505551234", "id" => "wamid.HBg",
            "timestamp" => "1750030073", "type" => "revoke",
            "revoke" => { "original_message_id" => "wamid.ORIGINAL" }, },
        ]
      ).message_echoes.first

      expect(echo.message).to be_a(Whatsapp::Webhook::Message::Revoke)
      expect(echo.message.original_message_id).to eq("wamid.ORIGINAL")
    end

    it "carries an edit the business made from the WhatsApp Business app" do
      echo = described_class.deserialize(
        "message_echoes" => [
          { "from" => "15550783881", "to" => "16505551234", "id" => "wamid.HBg",
            "timestamp" => "1750030073", "type" => "edit",
            "edit" => { "original_message_id" => "wamid.ORIGINAL",
                        "message" => { "type" => "text", "text" => { "body" => "corrected" } }, }, },
        ]
      ).message_echoes.first

      expect(echo.message).to be_a(Whatsapp::Webhook::Message::Edit)
      expect(echo.message.message.body).to eq("corrected")
    end

    it "tolerates a missing message_echoes array and contacts" do
      value = described_class.deserialize({})

      expect(value.message_echoes).to eq([])
      expect(value.contacts).to eq([])
      expect(value.metadata).to be_nil
    end

    it "keeps the untouched value hash, not a copy" do
      expect(described_class.deserialize(payload).raw).to equal(payload)
    end

    it "leaves raw an empty hash for a nil value" do
      expect(described_class.deserialize(nil).raw).to eq({})
    end
  end
end
