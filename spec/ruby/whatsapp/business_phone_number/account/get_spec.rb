# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::Account::Get do
  let(:edge) { "https://graph.facebook.com/v24.0/WABA_ID" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe "Fields" do
    it "lists every documented field" do
      expect(described_class::Fields::ALL).to eq(
        %w[id name timezone_id message_template_namespace account_review_status
           business_verification_status country ownership_type primary_business_location]
      )
    end

    it "freezes the list so a caller cannot mutate it" do
      expect(described_class::Fields::ALL).to be_frozen
    end
  end

  describe ".call" do
    it "gets the WABA node and returns the account details" do
      stub = stub_request(:get, edge)
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" })
        .to_return(status: 200, headers: json, body: {
          id: "102290129340398", name: "Acme Corp", account_review_status: "APPROVED",
        }.to_json)

      result = described_class.call

      expect(result).to be_a(Whatsapp::BusinessPhoneNumber::Account::Details)
      expect(result.name).to eq("Acme Corp")
      expect(result).to be_approved
      expect(stub).to have_been_requested
    end

    it "joins a fields array into a comma separated query parameter" do
      stub = stub_request(:get, edge)
        .with(query: { fields: "id,name,country" })
        .to_return(status: 200, headers: json, body: { id: "123" }.to_json)

      described_class.call(fields: %w[id name country])

      expect(stub).to have_been_requested
    end

    it "passes a fields string through unchanged" do
      stub = stub_request(:get, edge)
        .with(query: { fields: "id,name" })
        .to_return(status: 200, headers: json, body: { id: "123" }.to_json)

      described_class.call(fields: "id,name")

      expect(stub).to have_been_requested
    end

    it "requests every documented field when given Fields::ALL" do
      stub = stub_request(:get, edge)
        .with(query: { fields: described_class::Fields::ALL.join(",") })
        .to_return(status: 200, headers: json, body: { id: "123" }.to_json)

      described_class.call(fields: described_class::Fields::ALL)

      expect(stub).to have_been_requested
    end

    it "sends no fields parameter by default" do
      stub = stub_request(:get, edge)
        .with { |request| !request.uri.query.to_s.include?("fields") }
        .to_return(status: 200, headers: json, body: { id: "123" }.to_json)

      described_class.call

      expect(stub).to have_been_requested
    end

    it "accepts an injected client" do
      client = Whatsapp::Client.new(waba_id: "OTHER")
      stub = stub_request(:get, "https://graph.facebook.com/v24.0/OTHER")
        .to_return(status: 200, headers: json, body: { id: "OTHER" }.to_json)

      described_class.call(client:)

      expect(stub).to have_been_requested
    end

    it "raises when no waba_id is configured" do
      client = Whatsapp::Client.new(waba_id: nil)

      expect { described_class.call(client:) }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /waba_id/)
    end

    it "raises when the configured waba_id is blank" do
      client = Whatsapp::Client.new(waba_id: "")

      expect { described_class.call(client:) }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /waba_id/)
    end

    it "raises a BusinessPhoneNumber::Error when the API rejects the request" do
      stub_request(:get, edge).to_return(
        status: 404, headers: json,
        body: { error: { message: "WhatsApp Business Account not found", code: 803 } }.to_json
      )

      expect { described_class.call }
        .to raise_error(
          Whatsapp::BusinessPhoneNumber::Error,
          /Failed to get business account details.*WhatsApp Business Account not found/
        )
    end

    it "parses a response served as text/javascript" do
      js = { "Content-Type" => "text/javascript; charset=UTF-8" }
      stub_request(:get, edge).to_return(status: 200, headers: js, body: { name: "Acme Corp" }.to_json)

      expect(described_class.call.name).to eq("Acme Corp")
    end
  end
end
