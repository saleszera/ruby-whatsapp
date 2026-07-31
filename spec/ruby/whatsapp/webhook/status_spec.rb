# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Status do
  describe ".deserialize" do
    it "maps id, status, timestamp, recipient_id, conversation, pricing, and errors" do
      status = described_class.deserialize(
        "id" => "wamid.HBg",
        "status" => "delivered",
        "timestamp" => "1750263773",
        "recipient_id" => "16505551234",
        "conversation" => { "id" => "6ceb9d9", "origin" => { "type" => "service" } },
        "pricing" => { "billable" => true, "pricing_model" => "CBP", "category" => "service" },
        "errors" => [{ "code" => 131_026, "title" => "Message undeliverable", "message" => "m" }]
      )

      expect(status.id).to eq("wamid.HBg")
      expect(status.status).to eq("delivered")
      expect(status.timestamp).to eq("1750263773")
      expect(status.recipient_id).to eq("16505551234")
      expect(status.conversation).to be_a(Whatsapp::Webhook::Status::Conversation)
      expect(status.conversation.id).to eq("6ceb9d9")
      expect(status.conversation.origin_type).to eq("service")
      expect(status.pricing).to be_a(Whatsapp::Webhook::Status::Pricing)
      expect(status.pricing.billable).to be(true)
      expect(status.pricing.pricing_model).to eq("CBP")
      expect(status.pricing.category).to eq("service")
      expect(status.errors.first).to be_a(Whatsapp::Webhook::Error)
      expect(status.errors.first.code).to eq(131_026)
    end

    it "tolerates missing conversation, pricing, and errors" do
      status = described_class.deserialize("id" => "wamid.HBg", "status" => "sent")

      expect(status.conversation).to be_nil
      expect(status.pricing).to be_nil
      expect(status.errors).to eq([])
    end
  end
end
