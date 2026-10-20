# frozen_string_literal: true

module Whatsapp
  module Webhook
    # A WhatsApp user's business-scoped user ID (BSUID) changed — for example, after
    # they changed their phone number (see the `system` message type's
    # `user_changed_user_id` event) or were re-scoped by Meta.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
    class UserIdUpdate
      # @!attribute [rw] messaging_product
      #   @return [String, nil]
      attr_accessor :messaging_product

      # @!attribute [rw] metadata
      #   @return [Metadata, nil]
      attr_accessor :metadata

      # @!attribute [rw] contacts
      #   @return [Array<Contact>]
      attr_accessor :contacts

      # @!attribute [rw] updates
      #   @return [Array<Entry>]
      attr_accessor :updates

      # @!attribute [r] raw
      #   @return [Hash] The untouched `value` hash. A diagnostic escape hatch, not part
      #     of the supported API: {#updates} reads `value["user_id_update"]` — entries
      #     nested under a repeat of the field's own name, which is what Meta's published
      #     example shows — so a key that drifts would otherwise leave `updates` empty
      #     with no other trace. Reach for it when a typed accessor is unexpectedly
      #     `nil`, log what you find, and treat it as read-only: it is the object
      #     `JSON.parse` returned, not a copy.
      attr_reader :raw

      def initialize(messaging_product:, metadata:, contacts:, updates:, raw: {})
        @messaging_product = messaging_product
        @metadata = metadata
        @contacts = contacts
        @updates = updates
        @raw = raw
      end

      class << self
        # @param data [Hash] The raw `user_id_update` field's `value` hash.
        # @return [UserIdUpdate]
        def deserialize(data)
          data ||= {}

          new(
            messaging_product: data["messaging_product"],
            metadata: data["metadata"] ? Metadata.deserialize(data["metadata"]) : nil,
            contacts: Array(data["contacts"]).map { |contact_data| Contact.deserialize(contact_data) },
            updates: Array(data["user_id_update"]).map { |entry_data| Entry.deserialize(entry_data) },
            raw: data
          )
        end
      end
    end
  end
end
