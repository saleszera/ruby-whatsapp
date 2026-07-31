# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::TemplateCategoryUpdate do
  describe ".deserialize" do
    it "maps the template identity and the category change" do
      value = described_class.deserialize(
        "message_template_id" => 123,
        "message_template_name" => "order_confirmation",
        "message_template_language" => "en_US",
        "previous_category" => "MARKETING",
        "new_category" => "UTILITY",
        "correct_category" => "UTILITY"
      )

      expect(value.message_template_id).to eq(123)
      expect(value.previous_category).to eq("MARKETING")
      expect(value.new_category).to eq("UTILITY")
      expect(value.correct_category).to eq("UTILITY")
    end
  end
end
