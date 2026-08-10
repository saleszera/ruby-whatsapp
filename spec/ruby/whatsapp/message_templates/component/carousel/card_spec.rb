# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Component::Carousel::Card do
  let(:header) { { format: "IMAGE", header_handle: "4::aW" } }
  let(:buttons) { [{ type: :quick_reply, text: "More" }] }

  describe "#serialize" do
    it "wraps the card's parts in a components array with no card_index" do
      result = described_class.new(header:, buttons:).serialize

      expect(result).to eq(
        components: [
          { type: "HEADER", format: "IMAGE", example: { header_handle: ["4::aW"] } },
          { type: "BUTTONS", buttons: [{ type: "QUICK_REPLY", text: "More" }] },
        ]
      )
    end

    it "includes a body when given" do
      result = described_class.new(header:, body: { text: "Great value on {{1}}", example: ["mulch"] },
        buttons:).serialize

      expect(result[:components].map { |c| c[:type] }).to eq(%w[HEADER BODY BUTTONS])
    end

    it "omits buttons when none are given" do
      expect(described_class.new(header:).serialize[:components].map { |c| c[:type] }).to eq(%w[HEADER])
    end

    it "threads the parameter format down into the card body" do
      result = described_class.new(
        header:, body: { text: "Hi {{name}}", example: { name: "Pablo" } },
        parameter_format: Whatsapp::MessageTemplates::ParameterFormats::NAMED
      ).serialize

      expect(result[:components][1][:example]).to eq(
        body_text_named_params: [{ param_name: "name", example: "Pablo" }]
      )
    end
  end

  describe "validations" do
    it "requires a header" do
      expect { described_class.new(header: nil) }
        .to raise_error(ActiveModel::ValidationError, /Header can't be blank/)
    end

    it "accepts an image header" do
      expect { described_class.new(header: { format: "IMAGE", header_handle: "h" }) }.not_to raise_error
    end

    it "accepts a video header" do
      expect { described_class.new(header: { format: "VIDEO", header_handle: "h" }) }.not_to raise_error
    end

    it "rejects a text header, since carousel cards require media" do
      expect { described_class.new(header: { format: "TEXT", text: "Hi" }) }
        .to raise_error(ActiveModel::ValidationError, /must be IMAGE or VIDEO/)
    end

    it "rejects a document header" do
      expect { described_class.new(header: { format: "DOCUMENT", header_handle: "h" }) }
        .to raise_error(ActiveModel::ValidationError, /must be IMAGE or VIDEO/)
    end

    it "accepts 2 buttons" do
      expect { described_class.new(header:, buttons: [buttons.first, { type: :url, text: "Go", url: "https://x.test" }]) }
        .not_to raise_error
    end

    it "rejects more than 2 buttons" do
      three = [buttons.first, buttons.first, buttons.first]

      expect { described_class.new(header:, buttons: three) }
        .to raise_error(ActiveModel::ValidationError, /at most 2 buttons/)
    end
  end

  describe "#signature" do
    it "matches for cards with the same structure" do
      a = described_class.new(header:, buttons:)
      b = described_class.new(header: { format: "IMAGE", header_handle: "4::other" }, buttons:)

      expect(a.signature).to eq(b.signature)
    end

    it "differs when one card has a body and the other does not" do
      a = described_class.new(header:, buttons:)
      b = described_class.new(header:, body: { text: "Hi" }, buttons:)

      expect(a.signature).not_to eq(b.signature)
    end

    it "differs when the header formats differ" do
      a = described_class.new(header:, buttons:)
      b = described_class.new(header: { format: "VIDEO", header_handle: "h" }, buttons:)

      expect(a.signature).not_to eq(b.signature)
    end

    it "differs when the button types differ" do
      a = described_class.new(header:, buttons:)
      b = described_class.new(header:, buttons: [{ type: :url, text: "Go", url: "https://x.test" }])

      expect(a.signature).not_to eq(b.signature)
    end
  end
end
