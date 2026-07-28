# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Multi-Partner Solution status changes.
    #
    # Best-effort schema: Meta's public docs describe this field in one line with
    # no published JSON example. Validate against a real payload (App Dashboard
    # "send test payload") before relying on these attribute names in production.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class PartnerSolutions
      # @!attribute [rw] solution_id
      #   @return [String, nil]
      attr_accessor :solution_id

      # @!attribute [rw] event
      #   @return [String, nil]
      attr_accessor :event

      def initialize(solution_id:, event:)
        @solution_id = solution_id
        @event = event
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [PartnerSolutions]
        def deserialize(data)
          data ||= {}

          new(solution_id: data["solution_id"], event: data["event"])
        end
      end
    end
  end
end
