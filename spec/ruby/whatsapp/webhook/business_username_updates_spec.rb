# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::BusinessUsernameUpdates do
  describe ".deserialize" do
    it "maps display_phone_number, username, and status" do
      value = described_class.deserialize(
        "display_phone_number" => "15550783881",
        "username" => "jaspersmarket",
        "status" => "approved"
      )

      expect(value.display_phone_number).to eq("15550783881")
      expect(value.username).to eq("jaspersmarket")
      expect(value.status).to eq("approved")
    end

    it "tolerates a missing username, e.g. when status is deleted" do
      value = described_class.deserialize("display_phone_number" => "15550783881", "status" => "deleted")

      expect(value.username).to be_nil
      expect(value.status).to eq("deleted")
    end
  end
end
