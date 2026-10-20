# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::SmbMessageEchoes::Echo do
  describe ".deserialize" do
    it "splits the recipient identifiers from the echoed message" do
      echo = described_class.deserialize(
        "from" => "15550783881",
        "to" => "16505551234",
        "to_user_id" => "US.13491208655302741918",
        "to_parent_user_id" => "US.ENT.11815799212886844830",
        "id" => "wamid.HBg",
        "timestamp" => "1750030073",
        "type" => "text",
        "text" => { "body" => "Hi" }
      )

      expect(echo.to).to eq("16505551234")
      expect(echo.to_user_id).to eq("US.13491208655302741918")
      expect(echo.to_parent_user_id).to eq("US.ENT.11815799212886844830")
      expect(echo.message).to be_a(Whatsapp::Webhook::Message::Text)
      expect(echo.message.body).to eq("Hi")
    end

    it "tolerates an entry with no recipient identifiers at all" do
      echo = described_class.deserialize("type" => "text", "text" => { "body" => "Hi" })

      expect(echo.to).to be_nil
      expect(echo.to_user_id).to be_nil
      expect(echo.to_parent_user_id).to be_nil
      expect(echo.message).to be_a(Whatsapp::Webhook::Message::Text)
    end

    it "falls back to Message::Unknown for an unrecognized echo type" do
      echo = described_class.deserialize("to" => "16505551234", "type" => "telepathy")

      expect(echo.message).to be_a(Whatsapp::Webhook::Message::Unknown)
      expect(echo.to).to eq("16505551234")
    end

    it "tolerates a nil entry" do
      echo = described_class.deserialize(nil)

      expect(echo.to).to be_nil
      expect(echo.message).to be_a(Whatsapp::Webhook::Message::Unknown)
    end
  end
end
