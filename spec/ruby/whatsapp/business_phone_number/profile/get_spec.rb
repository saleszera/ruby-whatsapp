# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::Profile::Get do
  let(:edge) { "https://graph.facebook.com/v24.0/PHONE_ID/whatsapp_business_profile" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe "Fields" do
    it "lists every documented field" do
      expect(described_class::Fields::ALL).to eq(
        %w[messaging_product about address description email profile_picture_url websites vertical]
      )
    end

    it "freezes the list so a caller cannot mutate it" do
      expect(described_class::Fields::ALL).to be_frozen
    end
  end

  describe ".call" do
    it "gets the phone number's profile edge and returns the profile details" do
      stub = stub_request(:get, edge)
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" })
        .to_return(status: 200, headers: json, body: {
          data: [{ messaging_product: "whatsapp", about: "Open daily 9-5", vertical: "RETAIL" }],
        }.to_json)

      result = described_class.call

      expect(result).to be_a(Whatsapp::BusinessPhoneNumber::Profile::Details)
      expect(result.about).to eq("Open daily 9-5")
      expect(result.vertical).to eq("RETAIL")
      expect(stub).to have_been_requested
    end

    it "joins a fields array into a comma separated query parameter" do
      stub = stub_request(:get, edge)
        .with(query: { fields: "about,vertical,websites" })
        .to_return(status: 200, headers: json, body: { data: [{ about: "Open daily" }] }.to_json)

      described_class.call(fields: %w[about vertical websites])

      expect(stub).to have_been_requested
    end

    it "passes a fields string through unchanged" do
      stub = stub_request(:get, edge)
        .with(query: { fields: "about,vertical" })
        .to_return(status: 200, headers: json, body: { data: [{ about: "Open daily" }] }.to_json)

      described_class.call(fields: "about,vertical")

      expect(stub).to have_been_requested
    end

    it "requests every documented field when given Fields::ALL" do
      stub = stub_request(:get, edge)
        .with(query: { fields: described_class::Fields::ALL.join(",") })
        .to_return(status: 200, headers: json, body: { data: [{ about: "Open daily" }] }.to_json)

      described_class.call(fields: described_class::Fields::ALL)

      expect(stub).to have_been_requested
    end

    it "sends no fields parameter by default" do
      stub = stub_request(:get, edge)
        .with { |request| !request.uri.query.to_s.include?("fields") }
        .to_return(status: 200, headers: json, body: { data: [{ about: "Open daily" }] }.to_json)

      described_class.call

      expect(stub).to have_been_requested
    end

    it "addresses the configured phone_id rather than the waba_id" do
      stub = stub_request(:get, edge)
        .to_return(status: 200, headers: json, body: { data: [{ about: "Open daily" }] }.to_json)

      described_class.call

      expect(stub).to have_been_requested
      expect(a_request(:get, "https://graph.facebook.com/v24.0/WABA_ID/whatsapp_business_profile"))
        .not_to have_been_made
    end

    it "accepts an injected client" do
      client = Whatsapp::Client.new(phone_id: "OTHER")
      stub = stub_request(:get, "https://graph.facebook.com/v24.0/OTHER/whatsapp_business_profile")
        .to_return(status: 200, headers: json, body: { data: [{ about: "Open daily" }] }.to_json)

      described_class.call(client:)

      expect(stub).to have_been_requested
    end

    it "raises when no phone_id is configured" do
      client = Whatsapp::Client.new(phone_id: nil)

      expect { described_class.call(client:) }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /phone_id/)
    end

    it "raises when the configured phone_id is blank" do
      client = Whatsapp::Client.new(phone_id: "")

      expect { described_class.call(client:) }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /phone_id/)
    end

    it "names the exact configuration fix, and the edge, in the guard message" do
      client = Whatsapp::Client.new(phone_id: nil)

      expect { described_class.call(client:) }.to raise_error(
        Whatsapp::BusinessPhoneNumber::Error,
        "phone_id is required for the whatsapp_business_profile edge; " \
          "set it via Whatsapp.configure or Client.new(phone_id:)"
      )
    end

    it "makes no request when the ID guard trips" do
      client = Whatsapp::Client.new(phone_id: nil)

      expect { described_class.call(client:) }.to raise_error(Whatsapp::BusinessPhoneNumber::Error)
      expect(a_request(:get, edge)).not_to have_been_made
    end

    it "raises a BusinessPhoneNumber::Error when the API rejects the request" do
      stub_request(:get, edge).to_return(
        status: 404, headers: json,
        body: { error: { message: "WhatsApp Business Profile not found", code: 803 } }.to_json
      )

      expect { described_class.call }
        .to raise_error(
          Whatsapp::BusinessPhoneNumber::Error,
          /Failed to get business profile details.*WhatsApp Business Profile not found/
        )
    end

    it "parses a response served as text/javascript" do
      js = { "Content-Type" => "text/javascript; charset=UTF-8" }
      stub_request(:get, edge)
        .to_return(status: 200, headers: js, body: { data: [{ about: "Open daily" }] }.to_json)

      expect(described_class.call.about).to eq("Open daily")
    end
  end
end
