# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::UserIdUpdate do
  describe ".deserialize" do
    it "maps messaging_product, metadata, contacts, and the user_id_update entries" do
      value = described_class.deserialize(
        "messaging_product" => "whatsapp",
        "metadata" => { "display_phone_number" => "15550783881", "phone_number_id" => "106540352242922" },
        "contacts" => [{ "profile" => { "name" => "Jane Doe" }, "wa_id" => "16505551234" }],
        "user_id_update" => [
          {
            "wa_id" => "16505551234",
            "detail" => "User id for Jane Doe has been updated.",
            "user_id" => { "previous" => "US.OLD", "current" => "US.NEW" },
            "timestamp" => "1750030073",
          },
        ]
      )

      expect(value.messaging_product).to eq("whatsapp")
      expect(value.metadata).to be_a(Whatsapp::Webhook::Metadata)
      expect(value.metadata.phone_number_id).to eq("106540352242922")
      expect(value.contacts.first).to be_a(Whatsapp::Webhook::Contact)
      expect(value.contacts.first.wa_id).to eq("16505551234")
      expect(value.updates.first).to be_a(Whatsapp::Webhook::UserIdUpdate::Entry)
      expect(value.updates.first.user_id.current).to eq("US.NEW")
    end

    it "tolerates a missing metadata, contacts, and user_id_update" do
      value = described_class.deserialize("messaging_product" => "whatsapp")

      expect(value.metadata).to be_nil
      expect(value.contacts).to eq([])
      expect(value.updates).to eq([])
    end
  end
end
