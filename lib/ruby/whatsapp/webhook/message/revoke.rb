# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # A user deleted a message they had sent you. A control message rather than a
      # content one: it names a message you already received instead of carrying a body.
      #
      # Also arrives through {Whatsapp::Webhook::SmbMessageEchoes} when the business
      # itself revokes a message from the WhatsApp Business app.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/reference/messages/revoke
      class Revoke < Base
        # @!attribute [rw] original_message_id
        #   @return [String, nil] The wamid of the message that was deleted.
        attr_accessor :original_message_id

        def initialize(original_message_id: nil, **base_attributes)
          super(**base_attributes)

          @original_message_id = original_message_id
        end

        class << self
          # @param data [Hash] The raw message hash.
          # @return [Revoke]
          def deserialize(data)
            new(
              original_message_id: data.dig("revoke", "original_message_id"),
              **common_attributes(data)
            )
          end
        end
      end
    end
  end
end
