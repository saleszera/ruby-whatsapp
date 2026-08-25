# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Text do
  describe ".deserialize" do
    it "maps the envelope and the text body" do
      message = described_class.deserialize(
        "from" => "16505551234",
        "id" => "wamid.HBg",
        "timestamp" => "1749416383",
        "type" => "text",
        "text" => { "body" => "Does it come in another color?" }
      )

      expect(message.from).to eq("16505551234")
      expect(message.id).to eq("wamid.HBg")
      expect(message.timestamp).to eq("1749416383")
      expect(message.type).to eq("text")
      expect(message.body).to eq("Does it come in another color?")
      expect(message.context).to be_nil
    end

    it "maps from_user_id when the sender has a BSUID but has not adopted a username" do
      message = described_class.deserialize(
        "id" => "ABGGFlA5Fpa",
        "timestamp" => "1504902988",
        "from" => "16315551181",
        "from_user_id" => "US.13491208655302741918",
        "type" => "text",
        "text" => { "body" => "this is a text message" }
      )

      expect(message.from).to eq("16315551181")
      expect(message.from_user_id).to eq("US.13491208655302741918")
      expect(message.body).to eq("this is a text message")
    end

    it "omits from when the sender adopted a username and the phone number is unavailable" do
      message = described_class.deserialize(
        "id" => "ABGGFlA5Fpa",
        "timestamp" => "1504902988",
        "from_user_id" => "US.13491208655302741918",
        "type" => "text",
        "text" => { "body" => "this is a text message" }
      )

      expect(message.from).to be_nil
      expect(message.from_user_id).to eq("US.13491208655302741918")
    end

    it "deserializes the context when present" do
      message = described_class.deserialize(
        "type" => "text",
        "text" => { "body" => "yes" },
        "context" => { "from" => "1", "id" => "wamid.OLD" }
      )

      expect(message.context).to be_a(Whatsapp::Webhook::Message::Context)
      expect(message.context.id).to eq("wamid.OLD")
    end
  end
end
