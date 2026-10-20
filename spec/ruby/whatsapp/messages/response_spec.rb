# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Response do
  describe ".deserialize" do
    it "maps messaging_product, contacts, and messages" do
      data = {
        "messaging_product" => "whatsapp",
        "contacts" => [{ "input" => "+1", "wa_id" => "1" }],
        "messages" => [{ "id" => "wamid.9" }],
      }

      response = described_class.deserialize(data)

      expect(response.messaging_product).to eq("whatsapp")
      expect(response.contacts.first).to be_a(Whatsapp::Messages::Response::Contacts)
      expect(response.contacts.first.wa_id).to eq("1")
      expect(response.messages.first).to be_a(Whatsapp::Messages::Response::Messages)
      expect(response.messages.first.id).to eq("wamid.9")
    end

    it "tolerates missing contacts and messages keys" do
      response = described_class.deserialize({ "messaging_product" => "whatsapp" })

      expect(response.contacts).to eq([])
      expect(response.messages).to eq([])
    end

    it "maps success for status-update responses like mark-message-as-read" do
      response = described_class.deserialize({ "success" => true })

      expect(response.success).to be(true)
    end

    it "defaults success to nil when absent, for normal message-send responses" do
      response = described_class.deserialize({ "messaging_product" => "whatsapp" })

      expect(response.success).to be_nil
    end
  end

  describe Whatsapp::Messages::Response::Contacts do
    describe ".deserialize" do
      it "maps the BSUID when the message was addressed to one, with no phone number" do
        contact = described_class.deserialize(
          "input" => "US.13491208655302741918", "user_id" => "US.13491208655302741918"
        )

        expect(contact.input).to eq("US.13491208655302741918")
        expect(contact.user_id).to eq("US.13491208655302741918")
        expect(contact.wa_id).to be_nil
      end

      # Meta omits `user_id` whenever the message went to a phone number — including
      # when both `to` and `recipient` were supplied, since `to` takes precedence. So a
      # nil `user_id` does not mean the recipient has no BSUID.
      it "omits the BSUID when the message was addressed to a phone number" do
        contact = described_class.deserialize("input" => "+16505551234", "wa_id" => "16505551234")

        expect(contact.input).to eq("+16505551234")
        expect(contact.wa_id).to eq("16505551234")
        expect(contact.user_id).to be_nil
      end

      it "maps a parent BSUID, which Meta returns in the same user_id field" do
        contact = described_class.deserialize(
          "input" => "US.ENT.11815799212886844830", "user_id" => "US.ENT.11815799212886844830"
        )

        expect(contact.user_id).to eq("US.ENT.11815799212886844830")
      end

      it "tolerates both identifiers arriving together" do
        contact = described_class.deserialize(
          "input" => "+16505551234", "wa_id" => "16505551234", "user_id" => "US.13491208655302741918"
        )

        expect(contact.wa_id).to eq("16505551234")
        expect(contact.user_id).to eq("US.13491208655302741918")
      end
    end
  end
end
