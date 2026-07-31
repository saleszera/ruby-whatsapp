# frozen_string_literal: true

module Whatsapp
  module Webhook
    # A single `statuses[]` entry from the `messages` webhook field — a delivery
    # status update (sent/delivered/read/failed) for a message you sent.
    class Status
      # @!attribute [rw] id
      #   @return [String, nil] The wamid of the message this status is about.
      attr_accessor :id

      # @!attribute [rw] status
      #   @return [String, nil] `"sent"`, `"delivered"`, `"read"`, or `"failed"`.
      attr_accessor :status

      # @!attribute [rw] timestamp
      #   @return [String, nil]
      attr_accessor :timestamp

      # @!attribute [rw] recipient_id
      #   @return [String, nil]
      attr_accessor :recipient_id

      # @!attribute [rw] conversation
      #   @return [Conversation, nil]
      attr_accessor :conversation

      # @!attribute [rw] pricing
      #   @return [Pricing, nil]
      attr_accessor :pricing

      # @!attribute [rw] errors
      #   @return [Array<Error>]
      attr_accessor :errors

      def initialize(id:, status:, timestamp:, recipient_id:, conversation: nil, pricing: nil, errors: [])
        @id = id
        @status = status
        @timestamp = timestamp
        @recipient_id = recipient_id
        @conversation = conversation
        @pricing = pricing
        @errors = errors
      end

      class << self
        # @param data [Hash] A raw `statuses[]` entry.
        # @return [Status]
        def deserialize(data)
          data ||= {}

          new(
            id: data["id"],
            status: data["status"],
            timestamp: data["timestamp"],
            recipient_id: data["recipient_id"],
            conversation: data["conversation"] ? Conversation.deserialize(data["conversation"]) : nil,
            pricing: data["pricing"] ? Pricing.deserialize(data["pricing"]) : nil,
            errors: Array(data["errors"]).map { |error_data| Error.deserialize(error_data) }
          )
        end
      end
    end
  end
end
