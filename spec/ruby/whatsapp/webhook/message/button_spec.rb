# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Button do
  describe ".deserialize" do
    it "maps text and payload" do
      message = described_class.deserialize(
        "type" => "button",
        "button" => { "text" => "Confirm", "payload" => "CONFIRM_PAYLOAD" }
      )

      expect(message.text).to eq("Confirm")
      expect(message.payload).to eq("CONFIRM_PAYLOAD")
    end
  end
end
