# frozen_string_literal: true

module Whatsapp
  module Webhook
    # The `messages` webhook field's `value` payload — the only field with a
    # confirmed, JSON-example-backed schema in Meta's docs. Carries inbound
    # messages and/or delivery status updates for one of your business phone numbers.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class Messages
      # @!attribute [rw] messaging_product
      #   @return [String, nil]
      attr_accessor :messaging_product

      # @!attribute [rw] metadata
      #   @return [Metadata, nil]
      attr_accessor :metadata

      # @!attribute [rw] contacts
      #   @return [Array<Contact>]
      attr_accessor :contacts

      # @!attribute [rw] messages
      #   @return [Array<Message::Base>]
      attr_accessor :messages

      # @!attribute [rw] statuses
      #   @return [Array<Status>]
      attr_accessor :statuses

      def initialize(messaging_product:, metadata:, contacts:, messages:, statuses:)
        @messaging_product = messaging_product
        @metadata = metadata
        @contacts = contacts
        @messages = messages
        @statuses = statuses
      end

      class << self
        # @param data [Hash] The raw `messages` field's `value` hash.
        # @return [Messages]
        def deserialize(data)
          data ||= {}

          new(
            messaging_product: data["messaging_product"],
            metadata: data["metadata"] ? Metadata.deserialize(data["metadata"]) : nil,
            contacts: Array(data["contacts"]).map { |contact_data| Contact.deserialize(contact_data) },
            messages: Array(data["messages"]).map { |message_data| Message.deserialize(message_data) },
            statuses: Array(data["statuses"]).map { |status_data| Status.deserialize(status_data) }
          )
        end
      end
    end
  end
end
