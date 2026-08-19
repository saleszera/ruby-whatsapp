# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::Register do
  let(:edge) { "https://graph.facebook.com/v24.0/PHONE_ID/register" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe "#serialize" do
    it "emits the minimal documented payload" do
      result = described_class.new(pin: "212834").serialize

      expect(result).to eq(messaging_product: "whatsapp", pin: "212834")
    end

    it "includes data_localization_region when given" do
      result = described_class.new(pin: "212834", data_localization_region: "CH").serialize

      expect(result).to eq(messaging_product: "whatsapp", pin: "212834", data_localization_region: "CH")
    end

    it "normalizes a lowercase or symbol region to uppercase" do
      expect(described_class.new(pin: "212834", data_localization_region: :br).serialize[:data_localization_region])
        .to eq("BR")
      expect(described_class.new(pin: "212834", data_localization_region: "ch").serialize[:data_localization_region])
        .to eq("CH")
    end

    it "coerces an integer pin to its string form" do
      expect(described_class.new(pin: 212_834).serialize[:pin]).to eq("212834")
    end

    it "omits data_localization_region when unset" do
      expect(described_class.new(pin: "212834").serialize).not_to have_key(:data_localization_region)
    end
  end

  describe "pin validation" do
    it "rejects a pin shorter than 6 digits" do
      expect { described_class.new(pin: "1234") }
        .to raise_error(ActiveModel::ValidationError, /Pin must be exactly 6 digits/)
    end

    it "rejects a pin longer than 6 digits" do
      expect { described_class.new(pin: "1234567") }
        .to raise_error(ActiveModel::ValidationError, /Pin must be exactly 6 digits/)
    end

    it "rejects a non-numeric pin" do
      expect { described_class.new(pin: "abcdef") }
        .to raise_error(ActiveModel::ValidationError, /Pin must be exactly 6 digits/)
    end

    it "rejects a nil pin" do
      expect { described_class.new(pin: nil) }
        .to raise_error(ActiveModel::ValidationError, /Pin must be exactly 6 digits/)
    end

    it "rejects a blank pin" do
      expect { described_class.new(pin: "") }
        .to raise_error(ActiveModel::ValidationError, /Pin must be exactly 6 digits/)
    end

    it "accepts an integer pin that has exactly 6 digits" do
      expect { described_class.new(pin: 212_834) }.not_to raise_error
    end

    it "never echoes the pin value in the validation error message" do
      expect { described_class.new(pin: "1234") }
        .to raise_error(ActiveModel::ValidationError) { |error| expect(error.message).not_to include("1234") }
    end
  end

  describe "data_localization_region validation" do
    it "rejects an unsupported region code" do
      expect { described_class.new(pin: "212834", data_localization_region: "ZZ") }
        .to raise_error(ActiveModel::ValidationError, /Data localization region is not included in the list/)
    end

    it "accepts every documented region code" do
      %w[AU ID IN JP SG KR DE CH GB BR BH ZA AE CA].each do |code|
        expect { described_class.new(pin: "212834", data_localization_region: code) }.not_to raise_error
      end
    end
  end

  describe "#inspect" do
    it "redacts the pin" do
      result = described_class.new(pin: "212834", data_localization_region: "CH").inspect

      expect(result).not_to include("212834")
      expect(result).to include("pin=[REDACTED]")
      expect(result).to include('data_localization_region="CH"')
    end
  end

  describe ".call" do
    it "posts to the phone number's register edge and returns a response" do
      stub = stub_request(:post, edge)
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" }, body: { messaging_product: "whatsapp",
                                                                           pin: "212834", })
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      result = described_class.call(pin: "212834")

      expect(result).to be_a(Whatsapp::BusinessPhoneNumber::Response)
      expect(result.success).to be(true)
      expect(stub).to have_been_requested
    end

    it "posts the data_localization_region when given" do
      stub = stub_request(:post, edge)
        .with(body: { messaging_product: "whatsapp", pin: "212834", data_localization_region: "CH" })
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      described_class.call(pin: "212834", data_localization_region: "CH")

      expect(stub).to have_been_requested
    end

    it "accepts an injected client" do
      client = Whatsapp::Client.new(phone_id: "OTHER")
      stub = stub_request(:post, "https://graph.facebook.com/v24.0/OTHER/register")
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      described_class.call(pin: "212834", client:)

      expect(stub).to have_been_requested
    end

    it "raises when no phone_id is configured" do
      client = Whatsapp::Client.new(phone_id: nil)

      expect { described_class.call(pin: "212834", client:) }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /phone_id/)
    end

    it "names the exact configuration fix, and the edge, in the guard message" do
      client = Whatsapp::Client.new(phone_id: nil)

      expect { described_class.call(pin: "212834", client:) }.to raise_error(
        Whatsapp::BusinessPhoneNumber::Error,
        "phone_id is required for the register edge; set it via Whatsapp.configure or Client.new(phone_id:)"
      )
    end

    it "raises a BusinessPhoneNumber::Error when the API rejects the request" do
      stub_request(:post, edge).to_return(
        status: 400, headers: json, body: { error: { message: "Invalid parameter", code: 100 } }.to_json
      )

      expect { described_class.call(pin: "212834") }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error,
          /Failed to register business phone number.*Invalid parameter/)
    end

    it "reports an unsuccessful registration" do
      stub_request(:post, edge).to_return(status: 200, headers: json, body: { success: false }.to_json)

      expect(described_class.call(pin: "212834").success).to be(false)
    end

    it "parses a response served as text/javascript" do
      js = { "Content-Type" => "text/javascript; charset=UTF-8" }
      stub_request(:post, edge).to_return(status: 200, headers: js, body: { success: true }.to_json)

      expect(described_class.call(pin: "212834").success).to be(true)
    end

    it "raises a validation error before making any request for an invalid pin" do
      expect { described_class.call(pin: "123") }.to raise_error(ActiveModel::ValidationError)
      expect(a_request(:post, edge)).not_to have_been_made
    end
  end
end
