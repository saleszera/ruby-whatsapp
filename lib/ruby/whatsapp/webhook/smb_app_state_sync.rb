# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Contact synchronization for onboarded WhatsApp Business app users.
    #
    # Best-effort schema: Meta's public docs describe this field in one line with
    # no published JSON example; each entry's `contact` shape isn't confidently
    # typeable from that description alone, so it's kept as a raw hash rather
    # than guessing further. Validate against a real payload before relying on
    # this in production.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class SmbAppStateSync
      # @!attribute [rw] state_sync
      #   @return [Array<StateSync>]
      attr_accessor :state_sync

      def initialize(state_sync:)
        @state_sync = state_sync
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [SmbAppStateSync]
        def deserialize(data)
          data ||= {}

          new(state_sync: Array(data["state_sync"]).map { |entry| StateSync.deserialize(entry) })
        end
      end
    end
  end
end
