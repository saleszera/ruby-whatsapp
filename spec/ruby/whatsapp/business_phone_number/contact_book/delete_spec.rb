# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::ContactBook::Delete do
  let(:edge) { "https://graph.facebook.com/v24.0/PHONE_ID/contact_book" }
  let(:json) { { "Content-Type" => "application/json" } }
  let(:bsuid) { "US.13491208655302741918" }
  let(:query) { { messaging_product: "whatsapp", bsuid: } }

  describe "#serialize" do
    it "builds the query parameters, always including messaging_product" do
      expect(described_class.new(bsuid:).serialize)
        .to eq(messaging_product: "whatsapp", bsuid: "US.13491208655302741918")
    end
  end

  describe "validation" do
    it "requires a bsuid" do
      expect { described_class.new(bsuid: nil) }
        .to raise_error(ActiveModel::ValidationError, /Bsuid can't be blank/)
      expect { described_class.new(bsuid: "") }
        .to raise_error(ActiveModel::ValidationError, /Bsuid can't be blank/)
    end

    it "accepts a standard BSUID" do
      expect { described_class.new(bsuid:) }.not_to raise_error
    end

    # Meta states parent BSUIDs are not supported here, and this release hands callers
    # user_id and parent_user_id side by side, so the mix-up is worth catching locally.
    it "rejects a parent BSUID" do
      expect { described_class.new(bsuid: "US.ENT.11815799212886844830") }
        .to raise_error(ActiveModel::ValidationError, /looks like a parent BSUID/)
    end

    # Portfolio membership is account state the gem cannot see, so it is left to Meta.
    it "does not check portfolio membership, leaving it to the API" do
      stub_request(:delete, edge).with(query: { messaging_product: "whatsapp", bsuid: "GB.99999999999999999999" })
        .to_return(status: 400, headers: json, body: {
          error: { message: "Invalid parameter", code: 100 },
        }.to_json)

      expect { described_class.call(bsuid: "GB.99999999999999999999") }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /Failed to delete contact book entry/)
    end
  end

  describe ".call" do
    it "deletes the entry and reports that one was found" do
      stub = stub_request(:delete, edge)
        .with(query:, headers: { "Authorization" => "Bearer TEST_TOKEN" })
        .to_return(status: 200, headers: json, body: {
          messaging_product: "whatsapp", success: true, deleted: true,
        }.to_json)

      result = described_class.call(bsuid:)

      expect(result).to be_a(Whatsapp::BusinessPhoneNumber::ContactBook::Deletion)
      expect(result.success).to be(true)
      expect(result.deleted).to be(true)
      expect(stub).to have_been_requested
    end

    it "reports a successful request that found no entry" do
      stub_request(:delete, edge).with(query:)
        .to_return(status: 200, headers: json, body: { success: true, deleted: false }.to_json)

      result = described_class.call(bsuid:)

      expect(result.success).to be(true)
      expect(result.deleted).to be(false)
    end

    it "addresses an explicitly passed client's phone number" do
      client = Whatsapp::Client.new(phone_id: "OTHER")
      stub = stub_request(:delete, "https://graph.facebook.com/v24.0/OTHER/contact_book")
        .with(query:)
        .to_return(status: 200, headers: json, body: { success: true, deleted: true }.to_json)

      described_class.call(client:, bsuid:)

      expect(stub).to have_been_requested
    end

    it "raises when no phone_id is configured, without making a request" do
      client = Whatsapp::Client.new(phone_id: nil)

      expect { described_class.call(client:, bsuid:) }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /phone_id is required for the contact_book edge/)
      expect(a_request(:delete, edge)).not_to have_been_made
    end

    it "raises a BusinessPhoneNumber::Error when the API rejects the request" do
      stub_request(:delete, edge).with(query:).to_return(status: 403, headers: json, body: {
        error: { message: "Application does not have permission for this action", code: 10 },
      }.to_json)

      expect { described_class.call(bsuid:) }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /Failed to delete contact book entry/)
    end

    it "validates before spending a request" do
      expect { described_class.call(bsuid: "US.ENT.11815799212886844830") }
        .to raise_error(ActiveModel::ValidationError)
      expect(a_request(:delete, edge)).not_to have_been_made
    end
  end
end
