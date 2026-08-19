# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::Profile::Verticals do
  describe "ALL" do
    it "lists every documented vertical" do
      expect(described_class::ALL).to eq(
        %w[ALCOHOL APPAREL AUTO BEAUTY EDU ENTERTAIN EVENT_PLAN FINANCE GOVT GROCERY HEALTH
           HOTEL NONPROFIT ONLINE_GAMBLING OTC_DRUGS OTHER PHYSICAL_GAMBLING PROF_SERVICES
           RESTAURANT RETAIL TRAVEL]
      )
    end

    it "lists all 21 of them" do
      expect(described_class::ALL.size).to eq(21)
    end

    it "freezes the list so a caller cannot mutate it" do
      expect(described_class::ALL).to be_frozen
    end
  end

  describe ".normalize" do
    it "returns nil for nil" do
      expect(described_class.normalize(nil)).to be_nil
    end

    it "upcases a lowercase vertical" do
      expect(described_class.normalize("restaurant")).to eq("RESTAURANT")
    end

    it "accepts a symbol" do
      expect(described_class.normalize(:prof_services)).to eq("PROF_SERVICES")
    end

    it "passes a recognized value through unchanged" do
      expect(described_class.normalize("RETAIL")).to eq("RETAIL")
    end

    it "returns an unrecognized value untouched so the inclusion validator can report it" do
      expect(described_class.normalize("SPACESHIPS")).to eq("SPACESHIPS")
    end

    it "does not upcase an unrecognized value" do
      expect(described_class.normalize("spaceships")).to eq("spaceships")
    end
  end
end
