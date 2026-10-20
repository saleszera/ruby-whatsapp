# frozen_string_literal: true

RSpec.describe Whatsapp::Schedule::Create do
  let(:edge) { "https://graph.facebook.com/v24.0/WABA_ID/schedules" }
  let(:json) { { "Content-Type" => "application/json" } }
  let(:attributes) do
    {
      hsm_id: "1234567890",
      audience_id: "2345678901",
      waba_cs_id: "3456789012",
      name: "Black Friday",
      description: "Black Friday promo to VIP customers",
      delivery_time: 1_764_000_000,
    }
  end

  describe "#serialize" do
    it "sends every documented field" do
      expect(described_class.new(**attributes).serialize).to eq(attributes)
    end
  end

  describe "validation" do
    it "accepts every required field" do
      expect { described_class.new(**attributes) }.not_to raise_error
    end

    {
      hsm_id: /Hsm can't be blank/,
      audience_id: /Audience can't be blank/,
      waba_cs_id: /Waba cs can't be blank/,
      name: /Name can't be blank/,
      description: /Description can't be blank/,
    }.each do |field, message|
      it "rejects a nil #{field}" do
        expect { described_class.new(**attributes, field => nil) }
          .to raise_error(ActiveModel::ValidationError, message)
      end

      it "rejects a blank #{field}" do
        expect { described_class.new(**attributes, field => "") }
          .to raise_error(ActiveModel::ValidationError, message)
      end
    end

    it "rejects a nil delivery_time" do
      expect { described_class.new(**attributes, delivery_time: nil) }
        .to raise_error(ActiveModel::ValidationError, /Delivery time is not a number/)
    end

    it "rejects a fractional delivery_time" do
      expect { described_class.new(**attributes, delivery_time: 1_764_000_000.5) }
        .to raise_error(ActiveModel::ValidationError, /Delivery time must be an integer/)
    end

    it "rejects a non-numeric delivery_time" do
      expect { described_class.new(**attributes, delivery_time: "tomorrow") }
        .to raise_error(ActiveModel::ValidationError, /Delivery time is not a number/)
    end
  end

  describe ".call" do
    it "posts the schedule to the WABA edge and returns the new id" do
      stub = stub_request(:post, edge)
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" }, body: attributes.to_json)
        .to_return(status: 200, headers: json, body: { id: "9876543210" }.to_json)

      result = described_class.call(**attributes)

      expect(result).to be_a(Whatsapp::Schedule::Response::Created)
      expect(result.id).to eq("9876543210")
      expect(stub).to have_been_requested
    end

    it "accepts an injected client" do
      client = Whatsapp::Client.new(waba_id: "OTHER")
      stub = stub_request(:post, "https://graph.facebook.com/v24.0/OTHER/schedules")
        .to_return(status: 200, headers: json, body: { id: "9876543210" }.to_json)

      described_class.call(**attributes, client:)

      expect(stub).to have_been_requested
    end

    it "raises when no waba_id is configured" do
      client = Whatsapp::Client.new(waba_id: nil)

      expect { described_class.call(**attributes, client:) }
        .to raise_error(Whatsapp::Schedule::Error, /waba_id is required for schedules/)
    end

    it "raises a Schedule::Error when the API rejects the request" do
      stub_request(:post, edge).to_return(
        status: 403, headers: json,
        body: {
          error: {
            message: "Your app doesn't have permission to access this WhatsApp Business Account",
            type: "OAuthException", code: 200, error_subcode: 1_349_174,
          },
        }.to_json
      )

      expect { described_class.call(**attributes) }
        .to raise_error(Whatsapp::Schedule::Error, /Failed to create schedule.*permission/)
    end

    it "parses a response served as text/javascript" do
      js = { "Content-Type" => "text/javascript; charset=UTF-8" }
      stub_request(:post, edge).to_return(status: 200, headers: js, body: { id: "9876543210" }.to_json)

      expect(described_class.call(**attributes).id).to eq("9876543210")
    end

    it "raises a validation error before making any request" do
      expect { described_class.call(**attributes, name: "") }.to raise_error(ActiveModel::ValidationError)
      expect(a_request(:post, edge)).not_to have_been_made
    end
  end
end
