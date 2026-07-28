# frozen_string_literal: true

module Whatsapp
  class Messages
    class Response
      # @!attribute [rw] messaging_product
      #   @return [String]
      attr_accessor :messaging_product

      # @!attribute [rw] contacts
      #   @return [Array<Contacts>]
      attr_accessor :contacts

      # @!attribute [rw] messages
      #   @return [Array<Messages>]
      attr_accessor :messages

      # @!attribute [rw] success
      #   @return [Boolean, nil] Present on status-update responses (e.g. mark-message-as-read);
      #     nil on normal message-send responses.
      attr_accessor :success

      # @param messaging_product [String] The messaging product used (e.g., "whatsapp").
      # @param contacts [Array<Contacts>] The list of contact responses.
      # @param messages [Array<Messages>] The list of message responses.
      # @param success [Boolean, nil] The status-update success flag, if present.
      def initialize(messaging_product:, contacts:, messages:, success: nil)
        @messaging_product = messaging_product
        @contacts = contacts
        @messages = messages
        @success = success
      end

      class << self
        # Deserializes a hash into a Messages::Response object.
        # @param data [Hash] The hash representation of the message response.
        #   @return [Messages::Response] The deserialized message response object.
        def deserialize(data)
          new(
            messaging_product: data["messaging_product"],
            contacts: Array(data["contacts"]).map { |contact_data| Contacts.deserialize(contact_data) },
            messages: Array(data["messages"]).map { |message_data| Messages.deserialize(message_data) },
            success: data["success"]
          )
        end
      end
    end
  end
end
