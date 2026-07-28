# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # Present when an inbound message replies to a previous one (e.g. a reply
      # swipe, or a tap on an interactive button/list from an earlier message).
      class Context
        # @!attribute [rw] from
        #   @return [String, nil]
        attr_accessor :from

        # @!attribute [rw] id
        #   @return [String, nil] The wamid of the message being replied to.
        attr_accessor :id

        # @!attribute [rw] forwarded
        #   @return [Boolean, nil]
        attr_accessor :forwarded

        # @!attribute [rw] frequently_forwarded
        #   @return [Boolean, nil]
        attr_accessor :frequently_forwarded

        def initialize(from:, id:, forwarded: nil, frequently_forwarded: nil)
          @from = from
          @id = id
          @forwarded = forwarded
          @frequently_forwarded = frequently_forwarded
        end

        class << self
          # @param data [Hash, nil] The raw `context` hash.
          # @return [Context, nil]
          def deserialize(data)
            return if data.nil?

            new(
              from: data["from"],
              id: data["id"],
              forwarded: data["forwarded"],
              frequently_forwarded: data["frequently_forwarded"]
            )
          end
        end
      end
    end
  end
end
