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

      # @param messaging_product [String] The messaging product used (e.g., "whatsapp").
      # @param contacts [Array<Contacts>] The list of contact responses.
      # @param messages [Array<Messages>] The list of message responses.
      def initialize(messaging_product:, contacts:, messages:)
        @messaging_product = messaging_product
        @contacts = contacts
        @messages = messages
      end

      class << self
        # Deserializes a hash into a Messages::Response object.
        # @param data [Hash] The hash representation of the message response.
        #   @return [Messages::Response] The deserialized message response object.
        def deserialize(data)
          new(
            messaging_product: data["messaging_product"],
            contacts: Array(data["contacts"]).map { |contact_data| Contacts.deserialize(contact_data) },
            messages: Array(data["messages"]).map { |message_data| Messages.deserialize(message_data) }
          )
        end
      end
    end
  end
end
