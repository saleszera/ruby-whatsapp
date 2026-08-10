# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Component::Footer do
  describe "a text footer" do
    it "serializes the text" do
      expect(described_class.new(text: "Use the buttons below to manage subscriptions").serialize)
        .to eq(type: "FOOTER", text: "Use the buttons below to manage subscriptions")
    end

    it "accepts text at the 60 character limit" do
      expect { described_class.new(text: "a" * 60) }.not_to raise_error
    end

    it "rejects text over 60 characters" do
      expect { described_class.new(text: "a" * 61) }
        .to raise_error(ActiveModel::ValidationError, /Text is too long/)
    end

    it "rejects placeholders, which footers do not support" do
      expect { described_class.new(text: "Thanks {{1}}") }
        .to raise_error(ActiveModel::ValidationError, /does not support placeholders/)
    end
  end

  describe "an authentication footer" do
    it "serializes the code expiry instead of text" do
      expect(described_class.new(code_expiration_minutes: 15).serialize)
        .to eq(type: "FOOTER", code_expiration_minutes: 15)
    end

    it "accepts the lower bound of 1 minute" do
      expect { described_class.new(code_expiration_minutes: 1) }.not_to raise_error
    end

    it "accepts the upper bound of 90 minutes" do
      expect { described_class.new(code_expiration_minutes: 90) }.not_to raise_error
    end

    it "rejects 0 minutes" do
      expect { described_class.new(code_expiration_minutes: 0) }
        .to raise_error(ActiveModel::ValidationError, /must be in 1..90/)
    end

    it "rejects more than 90 minutes" do
      expect { described_class.new(code_expiration_minutes: 91) }
        .to raise_error(ActiveModel::ValidationError, /must be in 1..90/)
    end

    it "rejects a non-integer expiry" do
      expect { described_class.new(code_expiration_minutes: "fifteen") }
        .to raise_error(ActiveModel::ValidationError, /must be in 1..90/)
    end
  end

  describe "validations" do
    it "requires either text or a code expiry" do
      expect { described_class.new }
        .to raise_error(ActiveModel::ValidationError, /requires either text or code_expiration_minutes/)
    end

    it "rejects both together" do
      expect { described_class.new(text: "Thanks", code_expiration_minutes: 15) }
        .to raise_error(ActiveModel::ValidationError, /cannot be combined/)
    end
  end
end
