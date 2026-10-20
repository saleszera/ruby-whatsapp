# frozen_string_literal: true

RSpec.describe Whatsapp::Schedule::List do
  let(:edge) { "https://graph.facebook.com/v24.0/WABA_ID/schedules" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe "Fields" do
    it "lists every documented field" do
      expect(described_class::Fields::ALL).to eq(%w[id name description delivery_time status])
    end

    it "freezes the list so a caller cannot mutate it" do
      expect(described_class::Fields::ALL).to be_frozen
    end
  end

  describe ".call" do
    it "gets the WABA edge and returns a collection" do
      stub = stub_request(:get, edge)
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" })
        .to_return(status: 200, headers: json, body: {
          data: [{ name: "Black Friday", delivery_time: 1_764_000_000, status: "SCHEDULED" }],
        }.to_json)

      result = described_class.call

      expect(result).to be_a(Whatsapp::Schedule::Response::Collection)
      expect(result.map(&:name)).to eq(["Black Friday"])
      expect(result.first).to be_scheduled
      expect(stub).to have_been_requested
    end

    it "joins a fields array into a comma separated query parameter" do
      stub = stub_request(:get, edge)
        .with(query: { fields: "id,name,status" })
        .to_return(status: 200, headers: json, body: { data: [] }.to_json)

      described_class.call(fields: %w[id name status])

      expect(stub).to have_been_requested
    end

    it "passes a fields string through unchanged" do
      stub = stub_request(:get, edge)
        .with(query: { fields: "id,name" })
        .to_return(status: 200, headers: json, body: { data: [] }.to_json)

      described_class.call(fields: "id,name")

      expect(stub).to have_been_requested
    end

    it "requests every documented field when given Fields::ALL" do
      stub = stub_request(:get, edge)
        .with(query: { fields: described_class::Fields::ALL.join(",") })
        .to_return(status: 200, headers: json, body: { data: [] }.to_json)

      described_class.call(fields: described_class::Fields::ALL)

      expect(stub).to have_been_requested
    end

    it "sends the page size and cursors as query parameters" do
      stub = stub_request(:get, edge)
        .with(query: { limit: "25", after: "AFTER_CURSOR", before: "BEFORE_CURSOR" })
        .to_return(status: 200, headers: json, body: { data: [] }.to_json)

      described_class.call(limit: 25, after: "AFTER_CURSOR", before: "BEFORE_CURSOR")

      expect(stub).to have_been_requested
    end

    it "sends no query parameters by default" do
      stub = stub_request(:get, edge)
        .with { |request| request.uri.query.nil? }
        .to_return(status: 200, headers: json, body: { data: [] }.to_json)

      described_class.call

      expect(stub).to have_been_requested
    end

    it "fetches the next page from a previous result's cursor" do
      stub_request(:get, edge)
        .with { |request| request.uri.query.nil? }
        .to_return(status: 200, headers: json, body: {
          data: [{ name: "Black Friday" }], paging: { cursors: { after: "AFTER_CURSOR" } },
        }.to_json)
      next_page = stub_request(:get, edge)
        .with(query: { after: "AFTER_CURSOR" })
        .to_return(status: 200, headers: json, body: { data: [{ name: "Cyber Monday" }] }.to_json)

      first = described_class.call
      second = described_class.call(after: first.next_cursor)

      expect(second.map(&:name)).to eq(["Cyber Monday"])
      expect(next_page).to have_been_requested
    end

    it "accepts an injected client" do
      client = Whatsapp::Client.new(waba_id: "OTHER")
      stub = stub_request(:get, "https://graph.facebook.com/v24.0/OTHER/schedules")
        .to_return(status: 200, headers: json, body: { data: [] }.to_json)

      described_class.call(client:)

      expect(stub).to have_been_requested
    end

    it "names the exact configuration fix when no waba_id is configured" do
      client = Whatsapp::Client.new(waba_id: nil)

      expect { described_class.call(client:) }.to raise_error(
        Whatsapp::Schedule::Error,
        "waba_id is required for schedules; set it via Whatsapp.configure or Client.new(waba_id:)"
      )
    end

    it "raises when the configured waba_id is blank" do
      client = Whatsapp::Client.new(waba_id: "")

      expect { described_class.call(client:) }.to raise_error(Whatsapp::Schedule::Error, /waba_id/)
    end

    it "raises a Schedule::Error when the API rejects the request" do
      stub_request(:get, edge).to_return(
        status: 400, headers: json,
        body: { error: { message: "Invalid parameter", type: "OAuthException", code: 100 } }.to_json
      )

      expect { described_class.call }
        .to raise_error(Whatsapp::Schedule::Error, /Failed to list schedules.*Invalid parameter/)
    end

    it "parses a response served as text/javascript" do
      js = { "Content-Type" => "text/javascript; charset=UTF-8" }
      stub_request(:get, edge).to_return(status: 200, headers: js, body: { data: [{ name: "Black Friday" }] }.to_json)

      expect(described_class.call.map(&:name)).to eq(["Black Friday"])
    end
  end
end
