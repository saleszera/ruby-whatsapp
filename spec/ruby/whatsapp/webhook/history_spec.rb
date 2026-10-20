# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::History do
  describe ".deserialize" do
    # Meta's published payload. Before the BSUID docs shipped one, this class read
    # `phase`/`chunk_order`/`progress` from `value["metadata"]` and threads from
    # `value["threads"]` — but the sync metadata and threads live one level deeper, inside
    # each `value["history"][]` entry, while `value["metadata"]` is the ordinary
    # business-phone-number metadata. Every accessor was therefore permanently empty.
    # See https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids#history-webhooks
    let(:payload) do
      {
        "messaging_product" => "whatsapp",
        "metadata" => { "display_phone_number" => "15550783881", "phone_number_id" => "106540352242922" },
        "history" => [
          {
            "metadata" => { "phase" => 2, "chunk_order" => 1, "progress" => 50 },
            "threads" => [
              {
                "id" => "16505551234",
                "context" => {
                  "wa_id" => "16505551234",
                  "user_id" => "US.13491208655302741918",
                  "parent_user_id" => "US.ENT.11815799212886844830",
                  "username" => "pablomorales",
                },
                "messages" => [
                  { "from" => "16505551234",
                    "from_user_id" => "US.13491208655302741918",
                    "id" => "wamid.HBg",
                    "timestamp" => "1749416383",
                    "type" => "text",
                    "text" => { "body" => "Does it come in another color?" },
                    "history_context" => { "status" => "DELIVERED" }, },
                ],
              },
            ],
          },
        ],
      }
    end

    it "maps messaging_product and the business phone number metadata" do
      value = described_class.deserialize(payload)

      expect(value.messaging_product).to eq("whatsapp")
      expect(value.metadata).to be_a(Whatsapp::Webhook::Metadata)
      expect(value.metadata.phone_number_id).to eq("106540352242922")
    end

    it "maps each history entry to a chunk carrying its own sync metadata" do
      chunk = described_class.deserialize(payload).chunks.first

      expect(chunk).to be_a(Whatsapp::Webhook::History::Chunk)
      expect(chunk.phase).to eq(2)
      expect(chunk.chunk_order).to eq(1)
      expect(chunk.progress).to eq(50)
    end

    it "delegates phase, chunk_order, and progress to the first chunk" do
      value = described_class.deserialize(payload)

      expect(value.phase).to eq(2)
      expect(value.chunk_order).to eq(1)
      expect(value.progress).to eq(50)
    end

    it "maps a thread's id, BSUID context, and messages" do
      thread = described_class.deserialize(payload).chunks.first.threads.first

      expect(thread).to be_a(Whatsapp::Webhook::History::Thread)
      expect(thread.id).to eq("16505551234")
      expect(thread.context).to be_a(Whatsapp::Webhook::Contact)
      expect(thread.context.wa_id).to eq("16505551234")
      expect(thread.context.user_id).to eq("US.13491208655302741918")
      expect(thread.context.parent_user_id).to eq("US.ENT.11815799212886844830")
      expect(thread.context.username).to eq("pablomorales")
      expect(thread.messages.first).to be_a(Whatsapp::Webhook::Message::Text)
      expect(thread.messages.first.body).to eq("Does it come in another color?")
      expect(thread.messages.first.from_user_id).to eq("US.13491208655302741918")
    end

    it "keeps the untouched thread hash, so the unmodelled history_context is recoverable" do
      thread = described_class.deserialize(payload).chunks.first.threads.first

      expect(thread.raw.dig("messages", 0, "history_context", "status")).to eq("DELIVERED")
    end

    it "omits the thread id and phone number for a username-adopted user" do
      value = described_class.deserialize(
        "history" => [
          { "metadata" => { "phase" => 2, "chunk_order" => 1, "progress" => 50 },
            "threads" => [{ "context" => { "user_id" => "US.13491208655302741918", "username" => "pablomorales" } }], },
        ]
      )
      thread = value.chunks.first.threads.first

      expect(thread.id).to be_nil
      expect(thread.context.wa_id).to be_nil
      expect(thread.context.user_id).to eq("US.13491208655302741918")
      expect(thread.messages).to eq([])
    end

    it "tolerates a missing history array" do
      value = described_class.deserialize("messaging_product" => "whatsapp")

      expect(value.chunks).to eq([])
      expect(value.phase).to be_nil
      expect(value.chunk_order).to be_nil
      expect(value.progress).to be_nil
    end

    it "tolerates a chunk with no metadata and no threads" do
      chunk = described_class.deserialize("history" => [{}]).chunks.first

      expect(chunk.phase).to be_nil
      expect(chunk.threads).to eq([])
    end

    it "tolerates a thread with no context" do
      thread = described_class.deserialize("history" => [{ "threads" => [{ "id" => "1" }] }]).chunks.first.threads.first

      expect(thread.context).to be_nil
    end

    # The media-asset variant of this webhook carries the contacts and messages at the
    # value level instead of inside a thread.
    it "maps the value-level contacts and messages of the media-asset variant" do
      value = described_class.deserialize(
        "messaging_product" => "whatsapp",
        "contacts" => [
          { "profile" => { "username" => "pablomorales" },
            "wa_id" => "16505551234",
            "user_id" => "US.13491208655302741918", },
        ],
        "messages" => [
          { "from" => "16505551234", "from_user_id" => "US.13491208655302741918",
            "id" => "wamid.HBg", "timestamp" => "1749416383", "type" => "image",
            "image" => { "id" => "media.1", "mime_type" => "image/jpeg" }, },
        ]
      )

      expect(value.contacts.first).to be_a(Whatsapp::Webhook::Contact)
      expect(value.contacts.first.user_id).to eq("US.13491208655302741918")
      expect(value.messages.first).to be_a(Whatsapp::Webhook::Message::Image)
      expect(value.messages.first.media_id).to eq("media.1")
    end

    it "leaves the value-level contacts and messages empty for a thread-carrying payload" do
      value = described_class.deserialize(payload)

      expect(value.contacts).to eq([])
      expect(value.messages).to eq([])
    end

    it "keeps the untouched value hash, not a copy" do
      expect(described_class.deserialize(payload).raw).to equal(payload)
    end

    it "leaves raw an empty hash for a nil value" do
      expect(described_class.deserialize(nil).raw).to eq({})
    end
  end
end
