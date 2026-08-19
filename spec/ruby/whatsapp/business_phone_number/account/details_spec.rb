# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::Account::Details do
  let(:payload) do
    {
      "id" => "102290129340398",
      "name" => "Acme Corp",
      "timezone_id" => "1",
      "message_template_namespace" => "abcd1234_5678_90ef_ghij_klmnopqrstuv",
      "account_review_status" => "APPROVED",
      "business_verification_status" => "VERIFIED",
      "country" => "US",
      "ownership_type" => "SELF",
      "primary_business_location" => "US",
    }
  end

  describe ".deserialize" do
    it "reads every documented field" do
      details = described_class.deserialize(payload)

      expect(details).to have_attributes(
        id: "102290129340398",
        name: "Acme Corp",
        timezone_id: "1",
        message_template_namespace: "abcd1234_5678_90ef_ghij_klmnopqrstuv",
        account_review_status: "APPROVED",
        business_verification_status: "VERIFIED",
        country: "US",
        ownership_type: "SELF",
        primary_business_location: "US"
      )
    end

    it "tolerates a nil payload" do
      details = described_class.deserialize(nil)

      expect(details.id).to be_nil
      expect(details.name).to be_nil
    end

    it "tolerates a partial payload, leaving absent fields nil" do
      details = described_class.deserialize({ "id" => "123", "name" => "Acme Corp" })

      expect(details.id).to eq("123")
      expect(details.country).to be_nil
      expect(details.ownership_type).to be_nil
    end

    it "passes an undocumented status value through untouched" do
      details = described_class.deserialize({ "account_review_status" => "SOMETHING_NEW" })

      expect(details.account_review_status).to eq("SOMETHING_NEW")
    end
  end

  describe "status constants" do
    it "lists every documented review status" do
      expect(described_class::ReviewStatuses::ALL).to eq(%w[APPROVED DEFERRED PENDING REJECTED])
    end

    it "lists every documented verification status" do
      expect(described_class::VerificationStatuses::ALL).to eq(
        %w[EXPIRED FAILED INELIGIBLE NOT_VERIFIED PENDING PENDING_NEED_MORE_INFO
           PENDING_SUBMISSION REJECTED REVOKED VERIFIED]
      )
    end

    it "lists every documented ownership type" do
      expect(described_class::OwnershipTypes::ALL).to eq(%w[CLIENT_OWNED ON_BEHALF_OF SELF])
    end

    it "freezes each list so a caller cannot mutate it" do
      expect(described_class::ReviewStatuses::ALL).to be_frozen
      expect(described_class::VerificationStatuses::ALL).to be_frozen
      expect(described_class::OwnershipTypes::ALL).to be_frozen
    end
  end

  describe "#approved?" do
    it "is true when the account review status is APPROVED" do
      expect(described_class.deserialize({ "account_review_status" => "APPROVED" })).to be_approved
    end

    it "is false for every other documented review status" do
      %w[DEFERRED PENDING REJECTED].each do |status|
        expect(described_class.deserialize({ "account_review_status" => status })).not_to be_approved
      end
    end

    it "is false when the field is absent" do
      expect(described_class.deserialize({})).not_to be_approved
    end
  end

  describe "#verified?" do
    it "is true when the business verification status is VERIFIED" do
      expect(described_class.deserialize({ "business_verification_status" => "VERIFIED" })).to be_verified
    end

    it "is false for every other documented verification status" do
      %w[EXPIRED FAILED INELIGIBLE NOT_VERIFIED PENDING PENDING_NEED_MORE_INFO
         PENDING_SUBMISSION REJECTED REVOKED].each do |status|
        expect(described_class.deserialize({ "business_verification_status" => status })).not_to be_verified
      end
    end

    it "is false when the field is absent" do
      expect(described_class.deserialize({})).not_to be_verified
    end
  end

  describe "#self_owned?" do
    it "is true when the ownership type is SELF" do
      expect(described_class.deserialize({ "ownership_type" => "SELF" })).to be_self_owned
    end

    it "is false for every other documented ownership type" do
      %w[CLIENT_OWNED ON_BEHALF_OF].each do |type|
        expect(described_class.deserialize({ "ownership_type" => type })).not_to be_self_owned
      end
    end

    it "is false when the field is absent" do
      expect(described_class.deserialize({})).not_to be_self_owned
    end
  end
end
