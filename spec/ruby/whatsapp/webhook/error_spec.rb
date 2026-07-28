# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Error do
  describe ".deserialize" do
    it "maps code, title, message, and error_data.details" do
      error = described_class.deserialize(
        "code" => 131_051,
        "title" => "Unsupported message type",
        "message" => "Unsupported message type",
        "error_data" => { "details" => "Message type is not currently supported" }
      )

      expect(error.code).to eq(131_051)
      expect(error.title).to eq("Unsupported message type")
      expect(error.message).to eq("Unsupported message type")
      expect(error.details).to eq("Message type is not currently supported")
    end

    it "tolerates a missing error_data" do
      error = described_class.deserialize("code" => 1, "title" => "t", "message" => "m")

      expect(error.details).to be_nil
    end
  end
end
