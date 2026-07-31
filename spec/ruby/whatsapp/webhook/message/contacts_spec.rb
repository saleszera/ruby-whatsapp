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
  end
end
