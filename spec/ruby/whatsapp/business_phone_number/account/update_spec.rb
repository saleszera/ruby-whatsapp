# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::Account::Update do
  let(:edge) { "https://graph.facebook.com/v24.0/WABA_ID" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe "#serialize" do
    it "sends both fields when both are given" do
      expect(described_class.new(name: "Acme Corp", timezone_id: "1").serialize)
        .to eq({ name: "Acme Corp", timezone_id: "1" })
    end

    it "compacts away an omitted timezone_id" do
      expect(described_class.new(name: "Acme Corp").serialize).to eq({ name: "Acme Corp" })
    end

    it "compacts away an omitted name" do
      expect(described_class.new(timezone_id: "1").serialize).to eq({ timezone_id: "1" })
    end
  end

  describe "validation" do
    it "requires at least one attribute" do
      expect { described_class.new }
        .to raise_error(ActiveModel::ValidationError, /at least one of name or timezone_id/)
    end

    it "rejects a blank name" do
      expect { described_class.new(name: "") }.to raise_error(ActiveModel::ValidationError, /Name can't be blank/)
    end

    it "rejects a blank timezone_id" do
      expect { described_class.new(timezone_id: "") }
        .to raise_error(ActiveModel::ValidationError, /Timezone can't be blank/)
    end

    it "accepts a name alone" do
      expect { described_class.new(name: "Acme Corp") }.not_to raise_error
    end

    it "accepts a timezone_id alone" do
      expect { described_class.new(timezone_id: "1") }.not_to raise_error
    end
  end

  describe ".call" do
    it "posts to the WABA node and returns a response" do
      stub = stub_request(:post, edge)
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" }, body: { name: "Acme Corp" })
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      result = described_class.call(name: "Acme Corp")

      expect(result).to be_a(Whatsapp::BusinessPhoneNumber::Response)
      expect(result.success).to be(true)
      expect(stub).to have_been_requested
    end

    it "posts both fields when both are given" do
      stub = stub_request(:post, edge)
        .with(body: { name: "Acme Corp", timezone_id: "1" })
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      described_class.call(name: "Acme Corp", timezone_id: "1")

      expect(stub).to have_been_requested
    end

    it "accepts an injected client" do
      client = Whatsapp::Client.new(waba_id: "OTHER")
      stub = stub_request(:post, "https://graph.facebook.com/v24.0/OTHER")
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      described_class.call(name: "Acme Corp", client:)

      expect(stub).to have_been_requested
    end

    it "raises when no waba_id is configured" do
      client = Whatsapp::Client.new(waba_id: nil)

      expect { described_class.call(name: "Acme Corp", client:) }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /waba_id/)
    end

    it "raises a BusinessPhoneNumber::Error when the API rejects the request" do
      stub_request(:post, edge).to_return(
        status: 400, headers: json,
        body: { error: { message: "Invalid parameter: name must be a non-empty string", code: 100 } }.to_json
      )

      expect { described_class.call(name: "Acme Corp") }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /Failed to update business account.*non-empty string/)
    end

    it "reports an unsuccessful update" do
      stub_request(:post, edge).to_return(status: 200, headers: json, body: { success: false }.to_json)

      expect(described_class.call(name: "Acme Corp").success).to be(false)
    end

    it "parses a response served as text/javascript" do
      js = { "Content-Type" => "text/javascript; charset=UTF-8" }
      stub_request(:post, edge).to_return(status: 200, headers: js, body: { success: true }.to_json)

      expect(described_class.call(name: "Acme Corp").success).to be(true)
    end

    it "raises a validation error before making any request when no attribute is given" do
      expect { described_class.call }.to raise_error(ActiveModel::ValidationError)
      expect(a_request(:post, edge)).not_to have_been_made
    end
  end
end
