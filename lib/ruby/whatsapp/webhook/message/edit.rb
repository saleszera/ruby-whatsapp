# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # A user edited a message they had sent you. Like {Revoke}, a control message: it
      # names the message being replaced and carries the replacement content.
      #
      # Also arrives through {Whatsapp::Webhook::SmbMessageEchoes} when the business
      # itself edits a message from the WhatsApp Business app.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/reference/messages/edit
      class Edit < Base
        # @!attribute [rw] original_message_id
        #   @return [String, nil] The wamid of the message being replaced.
        attr_accessor :original_message_id

        # @!attribute [rw] message
        #   @return [Base, nil] The replacement content, dispatched by its own `type`
        #     through {Message.deserialize} like any other message.
        #
        #     It carries *content only*. Meta's example gives the nested payload a `type`,
        #     its type body, and a `context`, but no `from`/`id`/`timestamp` of its own —
        #     those belong to the outer envelope, so the nested message's equivalents read
        #     `nil`. Reach for `edit.id` and `edit.from`, not `edit.message.id`.
        attr_accessor :message

        def initialize(original_message_id: nil, message: nil, **base_attributes)
          super(**base_attributes)

          @original_message_id = original_message_id
          @message = message
        end

        class << self
          # @param data [Hash] The raw message hash.
          # @return [Edit]
          def deserialize(data)
            edit = data["edit"] || {}

            new(
              original_message_id: edit["original_message_id"],
              message: edit["message"] ? Message.deserialize(edit["message"]) : nil,
              **common_attributes(data)
            )
          end
        end
      end
    end
  end
end
