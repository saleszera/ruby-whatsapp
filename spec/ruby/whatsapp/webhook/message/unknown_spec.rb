# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Unknown do
  describe ".deserialize" do
    it "captures the raw payload and deserializes errors" do
      data = {
        "from" => "16505551234",
        "type" => "unsupported_future_type",
        "errors" => [{ "code" => 131_051, "title" => "Unsupported message type", "message" => "m" }],
      }

      message = described_class.deserialize(data)

      expect(message.from).to eq("16505551234")
      expect(message.raw).to eq(data)
      expect(message.errors.first).to be_a(Whatsapp::Webhook::Error)
      expect(message.errors.first.code).to eq(131_051)
    end

    it "tolerates no errors key" do
      message = described_class.deserialize("type" => "x")

      expect(message.errors).to eq([])
    end
  end
end
