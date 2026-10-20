# frozen_string_literal: true

module Whatsapp
  module Webhook
    # User marketing message preference changes (e.g. a customer opting out of
    # marketing messages) — one of the fields with a confirmed, JSON-example-backed
    # schema, alongside {Messages}, {UserIdUpdate}, and {BusinessUsernameUpdates}.
    #
    # Structurally identical to {UserIdUpdate}: the value carries the notification's
    # own identity (`messaging_product`, `metadata`, `contacts`) plus an array of
    # entries nested under a repeat of the field's own name.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
    class UserPreferences
      # @!attribute [rw] messaging_product
      #   @return [String, nil]
      attr_accessor :messaging_product

      # @!attribute [rw] metadata
      #   @return [Metadata, nil]
      attr_accessor :metadata

      # @!attribute [rw] contacts
      #   @return [Array<Contact>] The users whose preferences changed, carrying the same
      #     BSUID identifiers as every other `contacts[]` entry — which is how a
      #     username-adopted user is identifiable here at all once their phone number
      #     stops being shared.
      attr_accessor :contacts

      # @!attribute [rw] preferences
      #   @return [Array<Entry>]
      attr_accessor :preferences

      # @!attribute [r] raw
      #   @return [Hash] The untouched `value` hash. A diagnostic escape hatch, not part
      #     of the supported API: {#preferences} reads `value["user_preferences"]` —
      #     entries nested under a repeat of the field's own name, which is what Meta's
      #     published example shows — so a key that drifts would otherwise leave
      #     `preferences` empty with no other trace. Reach for it when a typed accessor is
      #     unexpectedly `nil`, log what you find, and treat it as read-only: it is the
      #     object `JSON.parse` returned, not a copy.
      attr_reader :raw

      def initialize(messaging_product:, metadata:, contacts:, preferences:, raw: {})
        @messaging_product = messaging_product
        @metadata = metadata
        @contacts = contacts
        @preferences = preferences
        @raw = raw
      end

      class << self
        # @param data [Hash] The raw `user_preferences` field's `value` hash.
        # @return [UserPreferences]
        def deserialize(data)
          data ||= {}

          new(
            messaging_product: data["messaging_product"],
            metadata: data["metadata"] ? Metadata.deserialize(data["metadata"]) : nil,
            contacts: Array(data["contacts"]).map { |contact_data| Contact.deserialize(contact_data) },
            preferences: Array(data["user_preferences"]).map { |entry_data| Entry.deserialize(entry_data) },
            raw: data
          )
        end
      end
    end
  end
end
