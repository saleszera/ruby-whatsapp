# frozen_string_literal: true

module Whatsapp
  class Messages
    # Marks a previously received message (and every earlier message in the
    # conversation) as read. Unlike every other message class, this has no
    # recipient or type envelope — it targets an existing message by ID.
    # Meta requires this within 30 days of receipt.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/mark-message-as-read
    class MarkMessageAsRead
      include ActiveModel::Validations

      module Defaults
        MESSAGING_PRODUCT = "whatsapp"
        STATUS = "read"
      end

      # @!attribute [rw] message_id
      #   @return [String]
      attr_accessor :message_id

      validates :message_id, presence: true

      # @param message_id [String] The WhatsApp message ID (WAMID) to mark as read.
      #  @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(message_id:)
        @message_id = message_id

        validate!
      end

      # @return [Hash] Serialized representation for the WhatsApp API.
      def serialize
        {
          messaging_product: Defaults::MESSAGING_PRODUCT,
          status: Defaults::STATUS,
          message_id:,
        }
      end
    end
  end
end
