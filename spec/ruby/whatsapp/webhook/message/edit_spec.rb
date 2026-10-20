# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Edit do
  let(:payload) do
    {
      "from" => "16505551234",
      "from_user_id" => "US.13491208655302741918",
      "id" => "wamid.HBg",
      "timestamp" => "1749416383",
      "type" => "edit",
      "edit" => {
        "original_message_id" => "wamid.ORIGINAL",
        "message" => {
          "context" => { "id" => "wamid.CONTEXT" },
          "type" => "image",
          "image" => { "caption" => "Now in blue", "mime_type" => "image/jpeg", "id" => "media.1" },
        },
      },
    }
  end

  describe ".deserialize" do
    it "maps the replaced message's id alongside the shared envelope" do
      message = described_class.deserialize(payload)

      expect(message.original_message_id).to eq("wamid.ORIGINAL")
      expect(message.from).to eq("16505551234")
      expect(message.from_user_id).to eq("US.13491208655302741918")
      expect(message.id).to eq("wamid.HBg")
      expect(message.type).to eq("edit")
    end

    it "dispatches the replacement content by its own type" do
      nested = described_class.deserialize(payload).message

      expect(nested).to be_a(Whatsapp::Webhook::Message::Image)
      expect(nested.caption).to eq("Now in blue")
      expect(nested.media_id).to eq("media.1")
      expect(nested.context.id).to eq("wamid.CONTEXT")
    end

    # The nested payload is content only; the envelope belongs to the outer edit.
    it "leaves the nested message's own envelope empty" do
      nested = described_class.deserialize(payload).message

      expect(nested.id).to be_nil
      expect(nested.timestamp).to be_nil
      expect(nested.from).to be_nil
    end

    it "tolerates a missing edit object" do
      message = described_class.deserialize("id" => "wamid.HBg", "timestamp" => "1", "type" => "edit")

      expect(message.original_message_id).to be_nil
      expect(message.message).to be_nil
    end

    it "leaves the nested message nil when only the original id is given" do
      message = described_class.deserialize(
        "id" => "wamid.HBg", "timestamp" => "1", "type" => "edit",
        "edit" => { "original_message_id" => "wamid.ORIGINAL" }
      )

      expect(message.original_message_id).to eq("wamid.ORIGINAL")
      expect(message.message).to be_nil
    end

    # Nested edits are semantically impossible and undocumented, but the payload comes off
    # the internet, so pin what the recursion actually does rather than leaving it latent.
    # A depth guard is deliberately absent: the generated controller verifies
    # X-Hub-Signature-256 before deserializing, so a hostile payload cannot get this far.
    it "recurses into an edit nested inside an edit" do
      message = described_class.deserialize(
        "id" => "wamid.HBg", "timestamp" => "1", "type" => "edit",
        "edit" => {
          "original_message_id" => "wamid.OUTER",
          "message" => {
            "type" => "edit",
            "edit" => { "original_message_id" => "wamid.INNER",
                        "message" => { "type" => "text", "text" => { "body" => "final" } }, },
          },
        }
      )

      expect(message.message).to be_a(described_class)
      expect(message.message.original_message_id).to eq("wamid.INNER")
      expect(message.message.message.body).to eq("final")
    end
  end
end
