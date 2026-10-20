# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Contact synchronization for onboarded WhatsApp Business app users: the address book
    # on the device, mirrored to your integration as entries are added, changed, or removed.
    #
    # Meta's BSUID documentation publishes the synced contact's shape, so
    # {StateSync#contact} is a typed {Contact} rather than a raw hash. The array key
    # itself (`state_sync`) is still inferred from the field name — hence {#raw}.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
    class SmbAppStateSync
      # @!attribute [rw] messaging_product
      #   @return [String, nil]
      attr_accessor :messaging_product

      # @!attribute [rw] metadata
      #   @return [Metadata, nil] The business phone number whose address book this is —
      #     not the per-entry metadata, whose timestamp is flattened onto {StateSync}.
      attr_accessor :metadata

      # @!attribute [rw] state_sync
      #   @return [Array<StateSync>]
      attr_accessor :state_sync

      # @!attribute [r] raw
      #   @return [Hash] The untouched `value` hash. A diagnostic escape hatch, not part of
      #     the supported API: {#state_sync} reads `value["state_sync"]`, a key inferred
      #     from the field's own name rather than confirmed by a published example, so a
      #     key that drifts would leave the array empty with no other trace. Read-only —
      #     it is the object `JSON.parse` returned, not a copy.
      attr_reader :raw

      def initialize(state_sync:, messaging_product: nil, metadata: nil, raw: {})
        @messaging_product = messaging_product
        @metadata = metadata
        @state_sync = state_sync
        @raw = raw
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [SmbAppStateSync]
        def deserialize(data)
          data ||= {}

          new(
            messaging_product: data["messaging_product"],
            metadata: data["metadata"] ? Metadata.deserialize(data["metadata"]) : nil,
            state_sync: Array(data["state_sync"]).map { |entry| StateSync.deserialize(entry) },
            raw: data
          )
        end
      end
    end
  end
end
