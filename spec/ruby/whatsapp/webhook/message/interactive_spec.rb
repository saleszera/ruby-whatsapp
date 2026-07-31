# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Interactive do
  describe ".deserialize" do
    it "maps a button_reply" do
      message = described_class.deserialize(
        "type" => "interactive",
        "interactive" => { "type" => "button_reply", "button_reply" => { "id" => "confirm", "title" => "Confirm" } }
      )

      expect(message.interactive_type).to eq("button_reply")
      expect(message.reply_id).to eq("confirm")
      expect(message.title).to eq("Confirm")
      expect(message.description).to be_nil
    end

    it "maps a list_reply" do
      message = described_class.deserialize(
        "type" => "interactive",
        "interactive" => {
          "type" => "list_reply",
          "list_reply" => { "id" => "espresso", "title" => "Espresso", "description" => "Strong & short" },
        }
      )

      expect(message.interactive_type).to eq("list_reply")
      expect(message.title).to eq("Espresso")
      expect(message.description).to eq("Strong & short")
    end
  end
end
