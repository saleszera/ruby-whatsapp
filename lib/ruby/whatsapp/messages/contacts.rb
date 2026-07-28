# frozen_string_literal: true

module Whatsapp
  class Messages
    # Contacts messages allow you to send rich contact information directly to WhatsApp users,
    # such as names, phone numbers, physical addresses, and email addresses.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/contacts-messages
    class Contacts < Base
      module Defaults
        TYPE = "contacts"
      end

      # @!attribute [rw] contacts
      #   @return [Array<Contact>]
      attr_accessor :contacts

      validates :contacts, presence: true, length: { maximum: 1 }

      # @param contacts [Array<Hash, Contact>] Array with exactly one contact.
      # @param kwargs [Hash] Additional keyword arguments passed to Base (:to).
      #  @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(contacts:, **)
        super(**)

        @contacts = contacts.map { |c| c.is_a?(Contact) ? c : Contact.new(**c) }

        validate!
      end

      # Serializes the contacts message to a hash format suitable for the WhatsApp API.
      # @return [Hash] The serialized contacts message.
      def serialize
        envelope(type: Defaults::TYPE, contacts: contacts.map(&:serialize))
      end
    end
  end
end
