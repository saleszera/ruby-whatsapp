# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::MessageTemplateComponentsUpdate do
  describe ".deserialize" do
    it "maps message_template_id, message_template_name, message_template_language, and message_template_element" do
      value = described_class.deserialize(
        "message_template_id" => 123,
        "message_template_name" => "order_confirmation",
        "message_template_language" => "en_US",
        "message_template_element" => "BODY"
      )

      expect(value.message_template_id).to eq(123)
      expect(value.message_template_name).to eq("order_confirmation")
      expect(value.message_template_language).to eq("en_US")
      expect(value.message_template_element).to eq("BODY")
    end
  end
end
