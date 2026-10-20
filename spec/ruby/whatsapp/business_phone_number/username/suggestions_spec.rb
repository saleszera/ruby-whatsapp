# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::Username::Suggestions do
  describe ".deserialize" do
    it "flattens Meta's doubly-wrapped envelope to a plain array" do
      suggestions = described_class.deserialize(
        "data" => [{ "username_suggestions" => %w[jaspersmarket jaspers_market] }]
      )

      expect(suggestions.suggestions).to eq(%w[jaspersmarket jaspers_market])
    end

    # Meta's example shows one data entry, but nothing documents that as a limit, so this
    # flattens across all of them rather than reading data[0] as Profile::Details does.
    it "flattens across every data entry" do
      suggestions = described_class.deserialize(
        "data" => [{ "username_suggestions" => %w[first] }, { "username_suggestions" => %w[second third] }]
      )

      expect(suggestions.suggestions).to eq(%w[first second third])
    end

    it "returns an empty list for every shape of nothing" do
      expect(described_class.deserialize({}).suggestions).to eq([])
      expect(described_class.deserialize(nil).suggestions).to eq([])
      expect(described_class.deserialize("data" => []).suggestions).to eq([])
      expect(described_class.deserialize("data" => [{}]).suggestions).to eq([])
      expect(described_class.deserialize("data" => [nil]).suggestions).to eq([])
    end
  end

  describe "Enumerable" do
    subject(:suggestions) do
      described_class.deserialize("data" => [{ "username_suggestions" => %w[jaspersmarket jaspers_market] }])
    end

    it "enumerates the reserved usernames" do
      expect(suggestions.first).to eq("jaspersmarket")
      expect(suggestions.to_a).to eq(%w[jaspersmarket jaspers_market])
      expect(suggestions.map(&:upcase)).to eq(%w[JASPERSMARKET JASPERS_MARKET])
    end

    it "returns an enumerator when called without a block" do
      expect(suggestions.each).to be_a(Enumerator)
    end

    it "returns self when called with a block" do
      seen = []

      expect(suggestions.each { |suggestion| seen << suggestion }).to be(suggestions)
      expect(seen).to eq(%w[jaspersmarket jaspers_market])
    end
  end
end
