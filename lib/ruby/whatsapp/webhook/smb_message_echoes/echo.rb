# frozen_string_literal: true

module Whatsapp
  module Webhook
    class SmbMessageEchoes
      # One echoed message: who the business sent it *to*, plus the message itself.
      #
      # A wrapper rather than three more accessors on {Message::Base}, deliberately.
      # `Base` is the envelope shared by every inbound message type, and an inbound
      # message can never carry a recipient — Meta's own convention is that a keyword
      # defaults to `nil` when a field is *conditional*, not when it is impossible.
      # Putting `to`/`to_user_id`/`to_parent_user_id` there to serve this one field would
      # hand fifteen classes three permanently-`nil` readers, and would turn the
      # `NoMethodError` that currently tells you `message.to` is meaningless into a silent
      # `nil`. Composing instead keeps {Message.deserialize}'s dispatch untouched, so an
      # echoed `revoke` or `edit` resolves exactly as an inbound one does.
      class Echo
        # @!attribute [rw] to
        #   @return [String, nil] The customer's phone number. Omitted once they adopt a
        #     username and it is no longer shareable — fall back to {#to_user_id}.
        attr_accessor :to

        # @!attribute [rw] to_user_id
        #   @return [String, nil] The customer's business-scoped user ID (BSUID).
        attr_accessor :to_user_id

        # @!attribute [rw] to_parent_user_id
        #   @return [String, nil] The customer's parent BSUID, present only when enrolled.
        attr_accessor :to_parent_user_id

        # @!attribute [rw] message
        #   @return [Message::Base] The echoed message, dispatched by `type` like any
        #     inbound one. Its `from` is the *business* number, not the customer's.
        attr_accessor :message

        def initialize(message:, to: nil, to_user_id: nil, to_parent_user_id: nil)
          @to = to
          @to_user_id = to_user_id
          @to_parent_user_id = to_parent_user_id
          @message = message
        end

        class << self
          # @param data [Hash, nil] A raw `message_echoes[]` entry.
          # @return [Echo]
          def deserialize(data)
            data ||= {}

            new(
              to: data["to"],
              to_user_id: data["to_user_id"],
              to_parent_user_id: data["to_parent_user_id"],
              message: Message.deserialize(data)
            )
          end
        end
      end
    end
  end
end
