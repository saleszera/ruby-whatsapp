# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Purchase or lead event detection from Click to WhatsApp ad conversations.
    #
    # Best-effort schema: Meta's public docs describe this field in one line with
    # no published JSON example; `event_data`'s nested shape isn't confidently
    # typeable from that description alone, so it's kept as a raw hash rather than
    # guessing further. Validate against a real payload before relying on this in
    # production.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class AutomaticEvents
      # @!attribute [rw] event_type
      #   @return [String, nil] e.g. `"purchase"`, `"lead"`.
      attr_accessor :event_type

      # @!attribute [rw] message_id
      #   @return [String, nil]
      attr_accessor :message_id

      # @!attribute [rw] event_data
      #   @return [Hash]
      attr_accessor :event_data

      def initialize(event_type:, message_id:, event_data:)
        @event_type = event_type
        @message_id = message_id
        @event_data = event_data
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [AutomaticEvents]
        def deserialize(data)
          data ||= {}

          new(event_type: data["event_type"], message_id: data["message_id"], event_data: data["event_data"] || {})
        end
      end
    end
  end
end
