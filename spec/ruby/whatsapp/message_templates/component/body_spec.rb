# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Component::Body do
  let(:named) { Whatsapp::MessageTemplates::ParameterFormats::NAMED }

  describe "a text body" do
    it "serializes static text with no example" do
      expect(described_class.new(text: "Thank you for your order.").serialize)
        .to eq(type: "BODY", text: "Thank you for your order.")
    end

    it "serializes positional variables with a nested body_text example" do
      result = described_class.new(
        text: "Thank you, {{1}}! Your order number is {{2}}.",
        example: %w[Pablo 860198-230332]
      ).serialize

      expect(result).to eq(
        type: "BODY",
        text: "Thank you, {{1}}! Your order number is {{2}}.",
        example: { body_text: [%w[Pablo 860198-230332]] }
      )
    end

    it "serializes named variables with a body_text_named_params example" do
      result = described_class.new(
        text: "Thank you, {{first_name}}! Your order number is {{order_number}}.",
        example: { first_name: "Pablo", order_number: "860198-230332" },
        parameter_format: named
      ).serialize

      expect(result[:example]).to eq(
        body_text_named_params: [
          { param_name: "first_name", example: "Pablo" },
          { param_name: "order_number", example: "860198-230332" },
        ]
      )
    end

    it "requires text" do
      expect { described_class.new(text: nil) }
        .to raise_error(ActiveModel::ValidationError, /Text can't be blank/)
    end

    it "accepts text at the 1024 character limit" do
      expect { described_class.new(text: "a" * 1024) }.not_to raise_error
    end

    it "rejects text over 1024 characters" do
      expect { described_class.new(text: "a" * 1025) }
        .to raise_error(ActiveModel::ValidationError, /Text is too long/)
    end

    it "requires an example when the text has variables" do
      expect { described_class.new(text: "Hi {{1}}") }
        .to raise_error(ActiveModel::ValidationError, /Example can't be blank/)
    end

    it "rejects fewer examples than placeholders" do
      expect { described_class.new(text: "Hi {{1}}, order {{2}}", example: ["Pablo"]) }
        .to raise_error(ActiveModel::ValidationError, /2 placeholders but 1 example/)
    end

    it "rejects more examples than placeholders" do
      expect { described_class.new(text: "Hi {{1}}", example: %w[Pablo extra]) }
        .to raise_error(ActiveModel::ValidationError, /1 placeholder but 2 examples/)
    end

    it "counts a repeated placeholder once" do
      expect { described_class.new(text: "Hi {{1}}, bye {{1}}", example: ["Pablo"]) }.not_to raise_error
    end

    it "rejects positional placeholders that do not start at 1" do
      expect { described_class.new(text: "Hi {{2}}", example: ["Pablo"]) }
        .to raise_error(ActiveModel::ValidationError, /must start at .*1.* and increment/)
    end

    it "rejects positional placeholders with a gap" do
      expect { described_class.new(text: "Hi {{1}}, order {{3}}", example: %w[a b]) }
        .to raise_error(ActiveModel::ValidationError, /must start at .*1.* and increment/)
    end

    it "rejects a mixed placeholder style" do
      expect { described_class.new(text: "Hi {{1}} and {{name}}", example: %w[a b]) }
        .to raise_error(ActiveModel::ValidationError, /mix/)
    end

    it "rejects named placeholders when the template is positional" do
      expect { described_class.new(text: "Hi {{first_name}}", example: { first_name: "Pablo" }) }
        .to raise_error(ActiveModel::ValidationError, /POSITIONAL/)
    end

    it "rejects positional placeholders when the template is named" do
      expect { described_class.new(text: "Hi {{1}}", example: ["Pablo"], parameter_format: named) }
        .to raise_error(ActiveModel::ValidationError, /NAMED/)
    end
  end

  describe "an authentication body" do
    it "serializes the security recommendation flag instead of text" do
      expect(described_class.new(add_security_recommendation: true).serialize)
        .to eq(type: "BODY", add_security_recommendation: true)
    end

    it "serializes a false flag" do
      expect(described_class.new(add_security_recommendation: false).serialize)
        .to eq(type: "BODY", add_security_recommendation: false)
    end

    it "rejects text alongside the flag" do
      expect { described_class.new(text: "Hi", add_security_recommendation: true) }
        .to raise_error(ActiveModel::ValidationError, /cannot be combined/)
    end
  end

  describe "#authentication?" do
    it "distinguishes the two shapes" do
      expect(described_class.new(add_security_recommendation: true)).to be_authentication
      expect(described_class.new(text: "Hi")).not_to be_authentication
    end
  end
end
