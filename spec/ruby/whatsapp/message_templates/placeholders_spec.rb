# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Placeholders do
  describe ".extract" do
    it "returns positional placeholder names in order of appearance" do
      expect(described_class.extract("Hi {{1}}, your order {{2}} shipped")).to eq(%w[1 2])
    end

    it "returns named placeholder names in order of appearance" do
      expect(described_class.extract("Hi {{first_name}}, order {{order_number}}")).to eq(%w[first_name order_number])
    end

    it "tolerates whitespace inside the braces" do
      expect(described_class.extract("Hi {{ first_name }}")).to eq(%w[first_name])
    end

    it "collapses repeated placeholders to a single entry" do
      expect(described_class.extract("{{1}} then {{1}} again")).to eq(%w[1])
    end

    it "returns an empty array when there are no placeholders" do
      expect(described_class.extract("No placeholders here")).to eq([])
    end

    it "returns an empty array for nil" do
      expect(described_class.extract(nil)).to eq([])
    end

    it "ignores malformed braces" do
      expect(described_class.extract("{{}} {{ }} {single} {{a-b}}")).to eq([])
    end
  end

  describe ".count" do
    it "counts unique placeholders" do
      expect(described_class.count("{{1}} {{2}} {{1}}")).to eq(2)
    end

    it "returns zero for text without placeholders" do
      expect(described_class.count("plain")).to eq(0)
    end
  end

  describe ".occurrences" do
    it "counts repeats rather than collapsing them, unlike .count" do
      expect(described_class.occurrences("{{1}} {{2}} {{1}}")).to eq(3)
      expect(described_class.count("{{1}} {{2}} {{1}}")).to eq(2)
    end

    it "returns zero for text without placeholders" do
      expect(described_class.occurrences("plain")).to eq(0)
    end

    it "returns zero for nil" do
      expect(described_class.occurrences(nil)).to eq(0)
    end

    it "ignores malformed braces" do
      expect(described_class.occurrences("{{}} {{ }} {single} {{a-b}}")).to eq(0)
    end
  end

  describe ".style" do
    it "detects a positional style" do
      expect(described_class.style("Hi {{1}} and {{2}}")).to eq(:positional)
    end

    it "detects a named style" do
      expect(described_class.style("Hi {{first_name}}")).to eq(:named)
    end

    it "detects a mixed style" do
      expect(described_class.style("Hi {{1}} and {{name}}")).to eq(:mixed)
    end

    it "returns nil when there are no placeholders" do
      expect(described_class.style("plain")).to be_nil
    end
  end

  describe ".positional?" do
    it "is true only when every placeholder is numeric" do
      expect(described_class).to be_positional("{{1}} {{2}}")
      expect(described_class).not_to be_positional("{{1}} {{name}}")
      expect(described_class).not_to be_positional("plain")
    end
  end

  describe ".named?" do
    it "is true only when every placeholder is non-numeric" do
      expect(described_class).to be_named("{{first_name}}")
      expect(described_class).not_to be_named("{{1}} {{name}}")
      expect(described_class).not_to be_named("plain")
    end
  end

  describe ".sequential?" do
    it "is true when positional placeholders start at 1 and increment" do
      expect(described_class).to be_sequential("{{1}} {{2}} {{3}}")
    end

    it "is true regardless of the order they appear in the text" do
      expect(described_class).to be_sequential("{{2}} comes after {{1}}")
    end

    it "is false when the sequence does not start at 1" do
      expect(described_class).not_to be_sequential("{{2}} {{3}}")
    end

    it "is false when the sequence has a gap" do
      expect(described_class).not_to be_sequential("{{1}} {{3}}")
    end

    it "is true for text with no placeholders" do
      expect(described_class).to be_sequential("plain")
    end
  end
end
