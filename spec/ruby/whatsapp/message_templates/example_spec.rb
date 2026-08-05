# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Example do
  let(:positional) { Whatsapp::MessageTemplates::ParameterFormats::POSITIONAL }
  let(:named) { Whatsapp::MessageTemplates::ParameterFormats::NAMED }

  describe ".serialize" do
    context "with the header role" do
      it "wraps positional values in a flat array under header_text" do
        result = described_class.serialize(role: :header, parameter_format: positional, values: ["Summer Sale"])

        expect(result).to eq(header_text: ["Summer Sale"])
      end

      it "maps named values under header_text_named_params" do
        result = described_class.serialize(
          role: :header, parameter_format: named, values: { sale_start_date: "December 1st" }
        )

        expect(result).to eq(
          header_text_named_params: [{ param_name: "sale_start_date", example: "December 1st" }]
        )
      end
    end

    context "with the body role" do
      it "wraps positional values in a nested array under body_text" do
        result = described_class.serialize(
          role: :body, parameter_format: positional, values: %w[Pablo 860198-230332]
        )

        expect(result).to eq(body_text: [%w[Pablo 860198-230332]])
      end

      it "maps named values under body_text_named_params" do
        result = described_class.serialize(
          role: :body, parameter_format: named,
          values: { first_name: "Pablo", order_number: "860198-230332" }
        )

        expect(result).to eq(
          body_text_named_params: [
            { param_name: "first_name", example: "Pablo" },
            { param_name: "order_number", example: "860198-230332" },
          ]
        )
      end
    end

    it "accepts a single scalar value as a one-element list" do
      expect(described_class.serialize(role: :header, parameter_format: positional, values: "Summer Sale"))
        .to eq(header_text: ["Summer Sale"])
    end

    it "accepts named values already in Meta's param_name/example array shape" do
      values = [{ param_name: "first_name", example: "Pablo" }]

      expect(described_class.serialize(role: :body, parameter_format: named, values:))
        .to eq(body_text_named_params: [{ param_name: "first_name", example: "Pablo" }])
    end

    it "passes through a hash that is already a built example payload" do
      values = { body_text: [%w[Pablo 860198]] }

      expect(described_class.serialize(role: :body, parameter_format: positional, values:))
        .to eq(body_text: [%w[Pablo 860198]])
    end

    it "passes through a built example payload given with string keys" do
      values = { "header_handle" => ["4::aW"] }

      expect(described_class.serialize(role: :header, parameter_format: positional, values:))
        .to eq(header_handle: ["4::aW"])
    end

    it "returns nil when there are no values" do
      expect(described_class.serialize(role: :body, parameter_format: positional, values: nil)).to be_nil
      expect(described_class.serialize(role: :body, parameter_format: positional, values: [])).to be_nil
      expect(described_class.serialize(role: :body, parameter_format: named, values: {})).to be_nil
    end

    it "raises for an unknown role" do
      expect { described_class.serialize(role: :footer, parameter_format: positional, values: ["x"]) }
        .to raise_error(ArgumentError, /Unknown example role/)
    end

    it "raises when named values are neither a hash nor a param_name array" do
      expect { described_class.serialize(role: :body, parameter_format: named, values: %w[Pablo]) }
        .to raise_error(ArgumentError, /named parameter examples/)
    end

    it "raises when a hash of names is given but the format is positional" do
      expect { described_class.serialize(role: :body, parameter_format: positional, values: { first_name: "Pablo" }) }
        .to raise_error(ArgumentError, /got a Hash.*parameter_format to NAMED/m)
    end

    it "raises when a named array entry is missing param_name" do
      expect { described_class.serialize(role: :body, parameter_format: named, values: [{ example: "Pablo" }]) }
        .to raise_error(ArgumentError, /named parameter examples/)
    end
  end

  describe ".count" do
    it "counts positional values" do
      expect(described_class.count(role: :body, parameter_format: positional, values: %w[a b])).to eq(2)
    end

    it "counts named values" do
      expect(described_class.count(role: :body, parameter_format: named, values: { a: 1, b: 2 })).to eq(2)
    end

    it "counts values inside a pre-built positional body payload" do
      expect(described_class.count(role: :body, parameter_format: positional,
        values: { body_text: [%w[a b c]] })).to eq(3)
    end

    it "counts values inside a pre-built named payload" do
      expect(described_class.count(role: :body, parameter_format: named,
        values: { body_text_named_params: [{ param_name: "a", example: "1" }] })).to eq(1)
    end

    it "is zero when there are no values" do
      expect(described_class.count(role: :body, parameter_format: positional, values: nil)).to eq(0)
    end
  end
end
