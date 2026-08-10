# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Component::Header do
  describe "a text header" do
    it "serializes static text with no example" do
      expect(described_class.new(format: "TEXT", text: "Your order shipped").serialize)
        .to eq(type: "HEADER", format: "TEXT", text: "Your order shipped")
    end

    it "serializes a positional variable with a flat header_text example" do
      result = described_class.new(format: "TEXT", text: "Our {{1}} is on!", example: ["Summer Sale"]).serialize

      expect(result).to eq(
        type: "HEADER", format: "TEXT", text: "Our {{1}} is on!",
        example: { header_text: ["Summer Sale"] }
      )
    end

    it "serializes a named variable with a header_text_named_params example" do
      result = described_class.new(
        format: "TEXT", text: "Our new sale starts {{sale_start_date}}!",
        example: { sale_start_date: "December 1st" },
        parameter_format: Whatsapp::MessageTemplates::ParameterFormats::NAMED
      ).serialize

      expect(result[:example]).to eq(
        header_text_named_params: [{ param_name: "sale_start_date", example: "December 1st" }]
      )
    end

    it "requires text" do
      expect { described_class.new(format: "TEXT", text: nil) }
        .to raise_error(ActiveModel::ValidationError, /Text can't be blank/)
    end

    it "accepts text at the 60 character limit" do
      expect { described_class.new(format: "TEXT", text: "a" * 60) }.not_to raise_error
    end

    it "rejects text over 60 characters" do
      expect { described_class.new(format: "TEXT", text: "a" * 61) }
        .to raise_error(ActiveModel::ValidationError, /Text is too long/)
    end

    it "rejects more than one variable" do
      expect { described_class.new(format: "TEXT", text: "{{1}} and {{2}}", example: %w[a b]) }
        .to raise_error(ActiveModel::ValidationError, /at most one variable/)
    end

    it "requires an example when the text has a variable" do
      expect { described_class.new(format: "TEXT", text: "Our {{1}} is on!") }
        .to raise_error(ActiveModel::ValidationError, /Example can't be blank/)
    end

    it "rejects Markdown formatting characters" do
      expect { described_class.new(format: "TEXT", text: "Your *order* shipped") }
        .to raise_error(ActiveModel::ValidationError, /Markdown/)
    end

    it "does not mistake the underscores in a named placeholder for Markdown" do
      expect do
        described_class.new(
          format: "TEXT", text: "Sale starts {{sale_start_date}}",
          example: { sale_start_date: "December 1st" },
          parameter_format: Whatsapp::MessageTemplates::ParameterFormats::NAMED
        )
      end.not_to raise_error
    end

    it "rejects a header_handle, which only media headers carry" do
      expect { described_class.new(format: "TEXT", text: "Hi", header_handle: "4::aW") }
        .to raise_error(ActiveModel::ValidationError, /cannot be set/)
    end
  end

  describe "a media header" do
    it "serializes a header_handle convenience value into the example payload" do
      expect(described_class.new(format: "IMAGE", header_handle: "4::aW").serialize)
        .to eq(type: "HEADER", format: "IMAGE", example: { header_handle: ["4::aW"] })
    end

    it "accepts a pre-built example payload" do
      expect(described_class.new(format: "DOCUMENT", example: { header_handle: ["4::YX"] }).serialize)
        .to eq(type: "HEADER", format: "DOCUMENT", example: { header_handle: ["4::YX"] })
    end

    it "supports every media format" do
      %w[IMAGE VIDEO DOCUMENT GIF].each do |format|
        expect(described_class.new(format:, header_handle: "4::aW").serialize[:format]).to eq(format)
      end
    end

    it "requires a handle" do
      expect { described_class.new(format: "IMAGE") }
        .to raise_error(ActiveModel::ValidationError, /Header handle can't be blank/)
    end

    it "rejects text on a media header" do
      expect { described_class.new(format: "IMAGE", header_handle: "4::aW", text: "Hi") }
        .to raise_error(ActiveModel::ValidationError, /cannot be set/)
    end
  end

  describe "a location header" do
    it "serializes with no text or example, since coordinates are supplied when sending" do
      expect(described_class.new(format: "LOCATION").serialize).to eq(type: "HEADER", format: "LOCATION")
    end

    it "rejects text" do
      expect { described_class.new(format: "LOCATION", text: "Here") }
        .to raise_error(ActiveModel::ValidationError, /cannot be set/)
    end

    it "rejects a header_handle" do
      expect { described_class.new(format: "LOCATION", header_handle: "4::aW") }
        .to raise_error(ActiveModel::ValidationError, /cannot be set/)
    end
  end

  describe "format validation" do
    it "requires a format" do
      expect { described_class.new(format: nil) }
        .to raise_error(ActiveModel::ValidationError, /Format can't be blank/)
    end

    it "rejects an unknown format" do
      expect { described_class.new(format: "HOLOGRAM") }
        .to raise_error(ActiveModel::ValidationError, /Format is not included/)
    end

    it "accepts lowercase and normalizes to Meta's uppercase" do
      expect(described_class.new(format: :image, header_handle: "4::aW").serialize[:format]).to eq("IMAGE")
    end
  end

  describe "#media?" do
    it "is true only for the media formats" do
      expect(described_class.new(format: "IMAGE", header_handle: "h")).to be_media
      expect(described_class.new(format: "TEXT", text: "Hi")).not_to be_media
      expect(described_class.new(format: "LOCATION")).not_to be_media
    end
  end
end
