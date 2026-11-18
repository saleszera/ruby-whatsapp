# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::ConversationalAutomation::Get do
  let(:node) { "https://graph.facebook.com/v24.0/PHONE_ID" }
  let(:json) { { "Content-Type" => "application/json" } }
  let(:body) do
    {
      conversational_automation: {
        prompts: ["Find the best hotels in the area"],
        commands: [{ command_name: "tickets", command_description: "Book flight tickets" }],
      },
      id: "PHONE_ID",
    }
  end

  describe ".call" do
    it "reads the conversational_automation field off the phone number node" do
      stub = stub_request(:get, node)
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" }, query: { fields: "conversational_automation" })
        .to_return(status: 200, headers: json, body: body.to_json)

      result = described_class.call

      expect(result).to be_a(Whatsapp::BusinessPhoneNumber::ConversationalAutomation::Details)
      expect(result.id).to eq("PHONE_ID")
      expect(result.prompts).to eq(["Find the best hotels in the area"])
      expect(result.commands).to eq([{ "command_name" => "tickets", "command_description" => "Book flight tickets" }])
      expect(stub).to have_been_requested
    end

    it "accepts an injected client" do
      client = Whatsapp::Client.new(phone_id: "OTHER")
      stub = stub_request(:get, "https://graph.facebook.com/v24.0/OTHER")
        .with(query: { fields: "conversational_automation" })
        .to_return(status: 200, headers: json, body: body.to_json)

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

    it "names the exact configuration fix, and the node, in the guard message" do
      client = Whatsapp::Client.new(phone_id: nil)

      expect { described_class.call(client:) }.to raise_error(
        Whatsapp::BusinessPhoneNumber::Error,
        "phone_id is required for the phone number node; " \
          "set it via Whatsapp.configure or Client.new(phone_id:)"
      )
    end

    it "makes no request when the ID guard trips" do
      client = Whatsapp::Client.new(phone_id: nil)

      expect { described_class.call(client:) }.to raise_error(Whatsapp::BusinessPhoneNumber::Error)
      expect(a_request(:get, /graph\.facebook\.com/)).not_to have_been_made
    end

    it "raises a BusinessPhoneNumber::Error when the API rejects the request" do
      stub_request(:get, node).with(query: hash_including({})).to_return(
        status: 404, headers: json,
        body: { error: { message: "WhatsApp Business phone number not found", code: 803 } }.to_json
      )

      expect { described_class.call }.to raise_error(
        Whatsapp::BusinessPhoneNumber::Error,
        /Failed to get conversational automation.*phone number not found/
      )
    end

    it "parses a response served as text/javascript" do
      js = { "Content-Type" => "text/javascript; charset=UTF-8" }
      stub_request(:get, node).with(query: hash_including({}))
        .to_return(status: 200, headers: js, body: body.to_json)

      expect(described_class.call.prompts).to eq(["Find the best hotels in the area"])
    end
  end
end
