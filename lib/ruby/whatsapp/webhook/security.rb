# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Phone number security settings modifications (e.g. two-step verification changes).
    #
    # Best-effort schema: Meta's public docs describe this field in one line with
    # no published JSON example. Validate against a real payload (App Dashboard
    # "send test payload") before relying on these attribute names in production.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class Security
      # @!attribute [rw] display_phone_number
      #   @return [String, nil]
      attr_accessor :display_phone_number

      # @!attribute [rw] event
      #   @return [String, nil]
      attr_accessor :event

      # @!attribute [rw] requester
      #   @return [String, nil]
      attr_accessor :requester

      def initialize(display_phone_number:, event:, requester: nil)
        @display_phone_number = display_phone_number
        @event = event
        @requester = requester
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [Security]
        def deserialize(data)
          data ||= {}

          new(display_phone_number: data["display_phone_number"], event: data["event"], requester: data["requester"])
        end
      end
    end
  end
end
