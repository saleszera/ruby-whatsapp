# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # An inbound emoji reaction to a previous message.
      class Reaction < Base
        # @!attribute [rw] message_id
        #   @return [String, nil] The wamid of the message being reacted to.
        attr_accessor :message_id

        # @!attribute [rw] emoji
        #   @return [String, nil] Empty when the user removed a previous reaction.
        attr_accessor :emoji

        def initialize(message_id:, emoji:, **base_attributes)
          super(**base_attributes)

          @message_id = message_id
          @emoji = emoji
        end

        class << self
          # @param data [Hash] The raw message hash.
          # @return [Reaction]
          def deserialize(data)
            new(
              message_id: data.dig("reaction", "message_id"),
              emoji: data.dig("reaction", "emoji"),
              **common_attributes(data)
            )
          end
        end
      end
    end
  end
end
