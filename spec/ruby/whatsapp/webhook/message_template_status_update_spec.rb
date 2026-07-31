# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::MessageTemplateStatusUpdate do
  describe ".deserialize" do
    it "maps the template identity, event, and reason" do
      value = described_class.deserialize(
        "message_template_id" => 123,
        "message_template_name" => "order_confirmation",
        "message_template_language" => "en_US",
        "event" => "REJECTED",
        "reason" => "INVALID_FORMAT"
      )

      expect(value.message_template_id).to eq(123)
      expect(value.message_template_name).to eq("order_confirmation")
      expect(value.message_template_language).to eq("en_US")
      expect(value.event).to eq("REJECTED")
      expect(value.reason).to eq("INVALID_FORMAT")
    end
  end
end
