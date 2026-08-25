# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::System do
  describe ".deserialize" do
    it "maps body, identity, wa_id, and the system change_type" do
      message = described_class.deserialize(
        "type" => "system",
        "system" => {
          "body" => "Jane changed to a new phone",
          "identity" => "ABCD1234",
          "wa_id" => "16505551234",
          "type" => "customer_changed_number",
        }
      )

      expect(message.body).to eq("Jane changed to a new phone")
      expect(message.identity).to eq("ABCD1234")
      expect(message.wa_id).to eq("16505551234")
      expect(message.change_type).to eq("customer_changed_number")
    end

    it "maps the system's new user_id and parent_user_id after a BSUID change" do
      message = described_class.deserialize(
        "type" => "system",
        "system" => {
          "body" => "User Jane changed from US.OLD to US.NEW",
          "wa_id" => "16505551234",
          "user_id" => "US.NEW",
          "parent_user_id" => "US.ENT.NEW",
          "type" => "user_changed_user_id",
        }
      )

      expect(message.user_id).to eq("US.NEW")
      expect(message.parent_user_id).to eq("US.ENT.NEW")
    end
  end
end
