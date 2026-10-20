# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Chat history synchronization for onboarded business customers — one of the fields
    # with a confirmed, JSON-example-backed schema, alongside {Messages},
    # {UserIdUpdate}, {BusinessUsernameUpdates}, and {UserPreferences}.
    #
    # History arrives in chunks. Each `history[]` entry is one {Chunk}, carrying its own
    # sync `metadata` (`phase`/`chunk_order`/`progress`) and the {Thread}s in it — note
    # that the value-level `metadata` is the ordinary business-phone-number
    # {Whatsapp::Webhook::Metadata}, a different object entirely.
    #
    # Meta sends a second variant of this field for a synced media asset, which carries
    # `contacts` and `messages` at the value level instead of inside a thread; both are
    # mapped here, and are empty for a thread-carrying payload.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
    class History
      # @!attribute [rw] messaging_product
      #   @return [String, nil]
      attr_accessor :messaging_product

      # @!attribute [rw] metadata
      #   @return [Metadata, nil] The business phone number this history belongs to — not
      #     the per-chunk sync metadata, which lives on {Chunk}.
      attr_accessor :metadata

      # @!attribute [rw] chunks
      #   @return [Array<Chunk>]
      attr_accessor :chunks

      # @!attribute [rw] contacts
      #   @return [Array<Contact>] Populated only by the media-asset variant.
      attr_accessor :contacts

      # @!attribute [rw] messages
      #   @return [Array<Message::Base>] Populated only by the media-asset variant; a
      #     thread-carrying payload puts its messages on {Thread#messages} instead.
      attr_accessor :messages

      # @!attribute [r] raw
      #   @return [Hash] The untouched `value` hash. A diagnostic escape hatch, not part of
      #     the supported API: this field has two payload variants and the deeper one nests
      #     three levels, so a key that drifts would leave a typed accessor empty with no
      #     other trace. Treat it as read-only — it is the object `JSON.parse` returned.
      attr_reader :raw

      def initialize(messaging_product:, metadata:, chunks:, contacts:, messages:, raw: {})
        @messaging_product = messaging_product
        @metadata = metadata
        @chunks = chunks
        @contacts = contacts
        @messages = messages
        @raw = raw
      end

      # A delivery normally carries exactly one chunk, so these three read through to it
      # rather than making every caller reach for `chunks.first`. Check {#chunks} directly
      # if you need to handle a multi-chunk delivery.
      # @return [Integer, nil]
      def phase
        chunks.first&.phase
      end

      # @return [Integer, nil]
      def chunk_order
        chunks.first&.chunk_order
      end

      # @return [Integer, nil] Percent complete, 0-100.
      def progress
        chunks.first&.progress
      end

      class << self
        # @param data [Hash] The raw `history` field's `value` hash.
        # @return [History]
        def deserialize(data)
          data ||= {}

          new(
            messaging_product: data["messaging_product"],
            metadata: data["metadata"] ? Metadata.deserialize(data["metadata"]) : nil,
            chunks: Array(data["history"]).map { |chunk_data| Chunk.deserialize(chunk_data) },
            contacts: Array(data["contacts"]).map { |contact_data| Contact.deserialize(contact_data) },
            messages: Array(data["messages"]).map { |message_data| Message.deserialize(message_data) },
            raw: data
          )
        end
      end
    end
  end
end
