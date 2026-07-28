# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # Common envelope shared by every inbound message type: who sent it, its
      # wamid, when it arrived, and (optionally) what it's replying to.
      class Base
        # @!attribute [rw] from
        #   @return [String, nil]
        attr_accessor :from

        # @!attribute [rw] id
        #   @return [String, nil] The message's wamid.
        attr_accessor :id

        # @!attribute [rw] timestamp
        #   @return [String, nil]
        attr_accessor :timestamp

        # @!attribute [rw] type
        #   @return [String, nil]
        attr_accessor :type

        # @!attribute [rw] context
        #   @return [Context, nil]
        attr_accessor :context

        # @!attribute [rw] referral
        #   @return [Referral, nil]
        attr_accessor :referral

        def initialize(from:, id:, timestamp:, type:, context: nil, referral: nil)
          @from = from
          @id = id
          @timestamp = timestamp
          @type = type
          @context = context
          @referral = referral
        end

        class << self
          # Extracts the fields every message type shares, for subclasses to
          # merge with their own type-specific payload before calling `new`.
          # @param data [Hash] The raw message hash.
          # @return [Hash]
          def common_attributes(data)
            {
              from: data["from"],
              id: data["id"],
              timestamp: data["timestamp"],
              type: data["type"],
              context: Context.deserialize(data["context"]),
              referral: Referral.deserialize(data["referral"]),
            }
          end
        end
      end
    end
  end
end
