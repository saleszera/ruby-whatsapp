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
  end
end
