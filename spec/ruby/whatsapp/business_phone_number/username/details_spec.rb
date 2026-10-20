# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::Username::Details do
  describe "Statuses" do
    it "lists the states Meta's own responses report" do
      expect(described_class::Statuses::ALL).to eq(%w[approved reserved])
    end

    it "freezes the list so a caller cannot mutate it" do
      expect(described_class::Statuses::ALL).to be_frozen
    end

    # "deleted" reaches you only through the business_username_updates webhook. Listing it
    # in a write-side enum would name a state no endpoint here can return.
    it "omits the webhook-only deleted state" do
      expect(described_class::Statuses::ALL).not_to include("deleted")
    end
  end

  describe ".deserialize" do
    it "maps username and status" do
      details = described_class.deserialize("username" => "jaspersmarket", "status" => "approved")

      expect(details.username).to eq("jaspersmarket")
      expect(details.status).to eq("approved")
    end

    it "leaves the username nil when the number has none set" do
      details = described_class.deserialize("status" => "reserved")

      expect(details.username).to be_nil
      expect(details.status).to eq("reserved")
    end

    it "tolerates an empty and a nil body" do
      expect(described_class.deserialize({}).status).to be_nil
      expect(described_class.deserialize(nil).status).to be_nil
    end

    it "keeps an unrecognized status as a raw string, so a new value round-trips" do
      details = described_class.deserialize("status" => "under_review")

      expect(details.status).to eq("under_review")
      expect(details).not_to be_approved
      expect(details).not_to be_reserved
    end
  end

  describe "#approved?" do
    it "is true only for the approved status" do
      expect(described_class.new(status: "approved")).to be_approved
      expect(described_class.new(status: "reserved")).not_to be_approved
      expect(described_class.new).not_to be_approved
    end
  end

  describe "#reserved?" do
    it "is true only for the reserved status" do
      expect(described_class.new(status: "reserved")).to be_reserved
      expect(described_class.new(status: "approved")).not_to be_reserved
      expect(described_class.new).not_to be_reserved
    end
  end
end
