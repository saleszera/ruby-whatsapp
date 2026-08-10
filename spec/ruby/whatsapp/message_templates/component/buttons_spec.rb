# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Component::Buttons do
  let(:quick_reply) { { type: :quick_reply, text: "Stop" } }
  let(:url) { { type: :url, text: "Shop", url: "https://x.test/shop" } }
  let(:phone) { { type: :phone_number, text: "Call", phone_number: "15550051310" } }

  describe "#serialize" do
    it "wraps each button under a single BUTTONS component" do
      result = described_class.new(buttons: [quick_reply, url]).serialize

      expect(result).to eq(
        type: "BUTTONS",
        buttons: [
          { type: "QUICK_REPLY", text: "Stop" },
          { type: "URL", text: "Shop", url: "https://x.test/shop" },
        ]
      )
    end

    it "accepts already-built button objects" do
      button = Whatsapp::MessageTemplates::Button::QuickReply.new(text: "Stop")

      expect(described_class.new(buttons: [button]).serialize[:buttons])
        .to eq([{ type: "QUICK_REPLY", text: "Stop" }])
    end

    it "preserves the declared order, which send-side button indexes depend on" do
      result = described_class.new(buttons: [url, phone, quick_reply]).serialize

      expect(result[:buttons].map { |b| b[:type] }).to eq(%w[URL PHONE_NUMBER QUICK_REPLY])
    end
  end

  describe "count validations" do
    it "requires at least one button" do
      expect { described_class.new(buttons: []) }
        .to raise_error(ActiveModel::ValidationError, /Buttons can't be blank/)
    end

    it "accepts 10 buttons" do
      expect { described_class.new(buttons: Array.new(10) { quick_reply }) }.not_to raise_error
    end

    it "rejects more than 10 buttons" do
      expect { described_class.new(buttons: Array.new(11) { quick_reply }) }
        .to raise_error(ActiveModel::ValidationError, /Buttons is too long/)
    end
  end

  describe "per-type caps" do
    it "rejects more than 2 URL buttons" do
      expect { described_class.new(buttons: [url, url, url]) }
        .to raise_error(ActiveModel::ValidationError, /at most 2 URL/)
    end

    it "rejects more than 1 phone number button" do
      expect { described_class.new(buttons: [phone, phone]) }
        .to raise_error(ActiveModel::ValidationError, /at most 1 PHONE_NUMBER/)
    end

    it "rejects more than 1 copy code button" do
      copy_code = { type: :copy_code, example: "250FF" }

      expect { described_class.new(buttons: [copy_code, copy_code]) }
        .to raise_error(ActiveModel::ValidationError, /at most 1 COPY_CODE/)
    end

    it "allows 2 URL buttons" do
      expect { described_class.new(buttons: [url, url]) }.not_to raise_error
    end
  end

  describe "quick reply contiguity" do
    it "allows quick replies grouped at the start" do
      expect { described_class.new(buttons: [quick_reply, quick_reply, url, phone]) }.not_to raise_error
    end

    it "allows quick replies grouped at the end" do
      expect { described_class.new(buttons: [url, phone, quick_reply, quick_reply]) }.not_to raise_error
    end

    it "allows a single quick reply anywhere" do
      expect { described_class.new(buttons: [url, quick_reply, phone]) }.not_to raise_error
    end

    it "rejects quick replies split by another type" do
      expect { described_class.new(buttons: [quick_reply, url, quick_reply]) }
        .to raise_error(ActiveModel::ValidationError, /must be grouped together/)
    end
  end

  describe "#api_types" do
    it "exposes the wire types in order, for cross-component checks" do
      expect(described_class.new(buttons: [url, quick_reply]).api_types).to eq(%w[URL QUICK_REPLY])
    end
  end
end
