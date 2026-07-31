# frozen_string_literal: true

RSpec.describe Whatsapp::Messages do
  let(:client) { Whatsapp::Client.new }

  describe "#initialize" do
    it "resolves a known symbol kind to its message class" do
      msg = described_class.new(kind: :text, payload: { to: "+1", body: "hi" }, client:)
      expect(msg.payload).to be_a(Whatsapp::Messages::Text)
    end

    it "accepts a string kind" do
      msg = described_class.new(kind: "template", payload: { to: "+1", name: "t", language: { code: "en_US" } },
        client:)
      expect(msg.payload).to be_a(Whatsapp::Messages::Template)
    end

    it "raises PayloadError for an unknown kind instead of resolving an arbitrary constant" do
      expect { described_class.new(kind: :env, payload: {}, client:) }
        .to raise_error(Whatsapp::Messages::PayloadError, /Unknown message kind/)
    end
  end

  describe "#send!" do
    let(:message) { described_class.new(kind: :text, payload: { to: "+1555", body: "hi" }, client:) }
    let(:endpoint) { "https://graph.facebook.com/v24.0/PHONE_ID/messages" }
    let(:success_body) do
      {
        messaging_product: "whatsapp",
        contacts: [{ input: "+1555", wa_id: "1555" }],
        messages: [{ id: "wamid.123" }],
      }.to_json
    end

    it "posts to the versioned endpoint with the bearer token and serialized body" do
      stub = stub_request(:post, endpoint)
        .with(
          headers: { "Authorization" => "Bearer TEST_TOKEN" },
          body: hash_including("type" => "text", "to" => "+1555")
        )
        .to_return(status: 200, body: success_body, headers: { "Content-Type" => "application/json" })

      response = message.send!

      expect(stub).to have_been_requested
      expect(response).to be_a(Whatsapp::Messages::Response)
      expect(response.messages.first.id).to eq("wamid.123")
      expect(response.contacts.first.wa_id).to eq("1555")
    end

    it "raises RequestError on a non-2xx response" do
      stub_request(:post, endpoint).to_return(status: 400, body: "bad request")

      expect { message.send! }.to raise_error(Whatsapp::RequestError, /Failed to send message/)
    end
  end

  describe "generated send_<kind>! class methods" do
    let(:endpoint) { "https://graph.facebook.com/v24.0/PHONE_ID/messages" }
    let(:success_body) do
      {
        messaging_product: "whatsapp",
        contacts: [{ input: "+1555", wa_id: "1555" }],
        messages: [{ id: "wamid.123" }],
      }.to_json
    end

    it "defines a bang-suffixed convenience method for every registered kind" do
      Whatsapp::Messages::KINDS.each_key do |kind|
        expect(described_class).to respond_to(:"send_#{kind}!")
      end
    end

    it "builds the message from the kwargs and sends it through the default client" do
      stub = stub_request(:post, endpoint)
        .with(
          headers: { "Authorization" => "Bearer TEST_TOKEN" },
          body: hash_including("type" => "text", "to" => "+1555")
        )
        .to_return(status: 200, body: success_body, headers: { "Content-Type" => "application/json" })

      response = described_class.send_text!(to: "+1555", body: "hi")

      expect(stub).to have_been_requested
      expect(response).to be_a(Whatsapp::Messages::Response)
      expect(response.messages.first.id).to eq("wamid.123")
    end

    it "forwards an explicitly passed client instead of defaulting" do
      custom_client = Whatsapp::Client.new(api_key: "CUSTOM_TOKEN", phone_id: "PHONE_ID")
      stub = stub_request(:post, endpoint)
        .with(headers: { "Authorization" => "Bearer CUSTOM_TOKEN" })
        .to_return(status: 200, body: success_body, headers: { "Content-Type" => "application/json" })

      described_class.send_text!(to: "+1555", body: "hi", client: custom_client)

      expect(stub).to have_been_requested
    end

    it "raises the same error an invalid payload would raise through .new(...).send!" do
      expect { described_class.send_text!(to: "+1555", body: nil) }
        .to raise_error(ActiveModel::ValidationError, /Body can't be blank/)
    end

    describe "kind-to-class dispatch" do
      it "builds the message class matching each kind registered in KINDS" do
        # Minimal valid payload for each registered kind, paired with the
        # message class its send_<kind>! method must build.
        payloads_by_kind = {
          text: [{ to: "+1", body: "hi" }, Whatsapp::Messages::Text],
          image: [{ to: "+1", link: "https://example.com/photo.jpg" }, Whatsapp::Messages::Image],
          video: [{ to: "+1", id: "vid123" }, Whatsapp::Messages::Video],
          audio: [{ to: "+1", link: "https://example.com/clip.mp3" }, Whatsapp::Messages::Audio],
          document: [{ to: "+1", link: "https://example.com/invoice.pdf" }, Whatsapp::Messages::Document],
          sticker: [{ to: "+1", id: "STICKER_ID" }, Whatsapp::Messages::Sticker],
          contacts: [
            { to: "+1", contacts: [{ name: { formatted_name: "Jane Doe" } }] },
            Whatsapp::Messages::Contacts,
          ],
          reaction: [{ to: "+1", message_id: "wamid.1", emoji: "👍" }, Whatsapp::Messages::Reaction],
          location: [{ to: "+1", latitude: 37.4847, longitude: -122.1477 }, Whatsapp::Messages::Location],
          address: [{ to: "+1", body: "Please share your address", country: "IN" }, Whatsapp::Messages::Address],
          location_request: [{ to: "+1", body: "Share your location?" }, Whatsapp::Messages::LocationRequest],
          template: [
            { to: "+1", name: "order_confirmation", language: { code: "en_US" } },
            Whatsapp::Messages::Template,
          ],
          interactive: [
            { to: "+1", type: :reply_buttons, body: "Pick one", action: { buttons: [{ id: "a", title: "A" }] } },
            Whatsapp::Messages::Interactive,
          ],
        }

        expect(payloads_by_kind.keys).to match_array(Whatsapp::Messages::KINDS.keys)

        stub_request(:post, endpoint)
          .to_return(status: 200, body: success_body, headers: { "Content-Type" => "application/json" })

        built = nil
        allow(described_class).to receive(:new).and_wrap_original do |original, **kwargs|
          original.call(**kwargs).tap { |instance| built = instance }
        end

        aggregate_failures "dispatch per kind" do
          payloads_by_kind.each do |kind, (payload, expected_class)|
            described_class.public_send(:"send_#{kind}!", **payload)

            expect(built.payload).to be_a(expected_class),
              "expected send_#{kind}! to build a #{expected_class}, got #{built.payload.class}"
          end
        end
      end
    end
  end

  describe ".mark_message_as_read!" do
    let(:message_id) { "wamid.HBgLMTY1MDM4Nzk0MzkVAgARGBJDQjZCMzlEQUE4OTJBMTE4RTUA" }
    let(:endpoint) { "https://graph.facebook.com/v24.0/PHONE_ID/messages" }
    let(:success_body) { { success: true }.to_json }

    it "posts the flat status-update body and returns a Response with success: true" do
      stub = stub_request(:post, endpoint)
        .with(
          headers: { "Authorization" => "Bearer TEST_TOKEN" },
          body: { messaging_product: "whatsapp", status: "read", message_id: }
        )
        .to_return(status: 200, body: success_body, headers: { "Content-Type" => "application/json" })

      response = described_class.mark_message_as_read!(message_id:)

      expect(stub).to have_been_requested
      expect(response).to be_a(Whatsapp::Messages::Response)
      expect(response.success).to be(true)
    end

    it "forwards an explicitly passed client instead of defaulting" do
      custom_client = Whatsapp::Client.new(api_key: "CUSTOM_TOKEN", phone_id: "PHONE_ID")
      stub = stub_request(:post, endpoint)
        .with(headers: { "Authorization" => "Bearer CUSTOM_TOKEN" })
        .to_return(status: 200, body: success_body, headers: { "Content-Type" => "application/json" })

      described_class.mark_message_as_read!(message_id:, client: custom_client)

      expect(stub).to have_been_requested
    end

    it "raises RequestError on a non-2xx response" do
      stub_request(:post, endpoint).to_return(status: 400, body: "bad request")

      expect { described_class.mark_message_as_read!(message_id:) }
        .to raise_error(Whatsapp::RequestError, /Failed to mark message as read/)
    end

    it "raises ActiveModel::ValidationError for a missing message_id" do
      expect { described_class.mark_message_as_read!(message_id: nil) }
        .to raise_error(ActiveModel::ValidationError, /Message can't be blank/)
    end

    it "is not registered as a message kind" do
      expect(Whatsapp::Messages::KINDS.keys).not_to include(:mark_message_as_read)
      expect(described_class).not_to respond_to(:send_mark_message_as_read!)
    end
  end
end
