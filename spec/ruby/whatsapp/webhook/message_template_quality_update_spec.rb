# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::MessageTemplateQualityUpdate do
  describe ".deserialize" do
    it "maps the template identity and the quality score change" do
      value = described_class.deserialize(
        "message_template_id" => 123,
        "message_template_name" => "order_confirmation",
        "message_template_language" => "en_US",
        "previous_quality_score" => "GREEN",
        "new_quality_score" => "YELLOW"
      )

      expect(value.message_template_id).to eq(123)
      expect(value.message_template_name).to eq("order_confirmation")
      expect(value.message_template_language).to eq("en_US")
      expect(value.previous_quality_score).to eq("GREEN")
      expect(value.new_quality_score).to eq("YELLOW")
    end
  end
end
