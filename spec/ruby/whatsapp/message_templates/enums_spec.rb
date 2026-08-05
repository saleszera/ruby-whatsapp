# frozen_string_literal: true

# The shared enum modules are exercised indirectly all over this suite; these examples
# pin down the parts that are public API for consumers of the gem — the constant names,
# the frozen lists, and the casing normalization every one of them performs because
# Meta's own documentation is inconsistent about it.
RSpec.describe "Whatsapp::MessageTemplates enums" do # rubocop:disable RSpec/DescribeClass
  describe Whatsapp::MessageTemplates::Categories do
    it "lists exactly Meta's three categories" do
      expect(described_class::ALL).to contain_exactly("AUTHENTICATION", "MARKETING", "UTILITY")
      expect(described_class::ALL).to be_frozen
    end

    it "normalizes any casing to uppercase" do
      expect(described_class.normalize(:marketing)).to eq("MARKETING")
      expect(described_class.normalize("utility")).to eq("UTILITY")
      expect(described_class.normalize("UTILITY")).to eq("UTILITY")
    end

    it "returns an unrecognized value untouched so validations can report it" do
      expect(described_class.normalize("PROMOTIONAL")).to eq("PROMOTIONAL")
      expect(described_class).not_to be_valid("PROMOTIONAL")
    end

    it "normalizes nil to nil" do
      expect(described_class.normalize(nil)).to be_nil
    end
  end

  describe Whatsapp::MessageTemplates::ParameterFormats do
    it "lists both formats" do
      expect(described_class::ALL).to contain_exactly("POSITIONAL", "NAMED")
      expect(described_class::ALL).to be_frozen
    end

    it "normalizes any casing" do
      expect(described_class.normalize(:named)).to eq("NAMED")
      expect(described_class.normalize("positional")).to eq("POSITIONAL")
    end

    it "answers whether a value is the named format" do
      expect(described_class).to be_named(:named)
      expect(described_class).not_to be_named("POSITIONAL")
      expect(described_class).not_to be_named(nil)
    end
  end

  describe Whatsapp::MessageTemplates::Statuses do
    it "lists every documented status" do
      expect(described_class::ALL).to include(
        "APPROVED", "PENDING", "REJECTED", "PAUSED", "DISABLED",
        "IN_APPEAL", "PENDING_DELETION", "DELETED", "LIMIT_EXCEEDED", "ARCHIVED"
      )
      expect(described_class::ALL).to be_frozen
    end

    it "lists only the statuses Meta allows editing in" do
      expect(described_class::EDITABLE).to contain_exactly("APPROVED", "REJECTED", "PAUSED")
    end

    it "exposes the rejection reasons" do
      expect(described_class::RejectedReasons::ALL).to contain_exactly(
        "NONE", "ABUSIVE_CONTENT", "INVALID_FORMAT", "PROMOTIONAL", "TAG_CONTENT_MISMATCH", "SCAM"
      )
    end

    it "exposes the quality score buckets" do
      expect(described_class::QualityScores::ALL).to contain_exactly("GREEN", "YELLOW", "RED", "UNKNOWN")
    end
  end

  describe Whatsapp::MessageTemplates::ValueObject do
    let(:klass) do
      Class.new do
        include Whatsapp::MessageTemplates::ValueObject
      end
    end

    it "requires subclasses to implement serialize" do
      expect { klass.new.serialize }
        .to raise_error(NotImplementedError, /must implement the serialize method/)
    end

    it "brings ActiveModel validations along" do
      expect(klass.new).to respond_to(:valid?, :errors)
    end

    it "does not shadow Object#blank?, which ActiveModel's presence validator relies on" do
      expect(klass.new.blank?).to be(false)
    end
  end
end
