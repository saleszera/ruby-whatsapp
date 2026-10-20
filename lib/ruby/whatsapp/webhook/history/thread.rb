# frozen_string_literal: true

module Whatsapp
  module Webhook
    class History
      # One conversation within a history {Chunk}: who it is with, and the messages in it.
      #
      # Named for Meta's `threads[]` key. Nested under {History}, so it never shadows
      # `::Thread` for anything outside this class.
      class Thread
        # @!attribute [rw] id
        #   @return [String, nil] The thread's identifier — the user's phone number, omitted
        #     if they had already adopted a username when the sync was requested and their
        #     number was no longer shareable. Use {#context} to identify them instead.
        attr_accessor :id

        # @!attribute [rw] context
        #   @return [Contact, nil] Who the thread is with (`wa_id`, `user_id`,
        #     `parent_user_id`, `username`). Deserialized with the same
        #     {Whatsapp::Webhook::Contact} as every other contact entry — its `username`
        #     read already falls back to a flat key, which is where Meta puts it here, and
        #     its `profile_name` is simply `nil` since a thread context carries no profile.
        attr_accessor :context

        # @!attribute [rw] messages
        #   @return [Array<Message::Base>] The synced messages, dispatched by `type` like
        #     any inbound message.
        #
        #     Each one also carries a `history_context.status` (its delivery state at sync
        #     time), which is **not** modelled: it would put a history-only field on
        #     `Message::Base`, the envelope shared by every inbound message type, where it
        #     could never appear. Read it from {#raw} instead.
        attr_accessor :messages

        # @!attribute [r] raw
        #   @return [Hash] The untouched thread hash, so the unmodelled per-message
        #     `history_context` stays reachable. Read-only; not a copy.
        attr_reader :raw

        def initialize(id: nil, context: nil, messages: [], raw: {})
          @id = id
          @context = context
          @messages = messages
          @raw = raw
        end

        class << self
          # @param data [Hash, nil] A raw `threads[]` entry.
          # @return [Thread]
          def deserialize(data)
            data ||= {}

            new(
              id: data["id"],
              context: data["context"] ? Contact.deserialize(data["context"]) : nil,
              messages: Array(data["messages"]).map { |message_data| Message.deserialize(message_data) },
              raw: data
            )
          end
        end
      end
    end
  end
end
