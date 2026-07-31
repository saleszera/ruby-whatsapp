# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Notifications of messaging limit, business profile, and Official Business
    # Account status changes.
    #
    # Best-effort schema: Meta's public docs describe this field in one line with
    # no published JSON example. Validate against a real payload (App Dashboard
    # "send test payload") before relying on these attribute names in production.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class AccountAlerts
      # @!attribute [rw] entity_type
      #   @return [String, nil]
      attr_accessor :entity_type

      # @!attribute [rw] entity_id
      #   @return [String, nil]
      attr_accessor :entity_id

      # @!attribute [rw] alert_severity
      #   @return [String, nil]
      attr_accessor :alert_severity

      # @!attribute [rw] alert_status
      #   @return [String, nil]
      attr_accessor :alert_status

      # @!attribute [rw] alert_description
      #   @return [String, nil]
      attr_accessor :alert_description

      def initialize(entity_type:, entity_id:, alert_severity:, alert_status:, alert_description:)
        @entity_type = entity_type
        @entity_id = entity_id
        @alert_severity = alert_severity
        @alert_status = alert_status
        @alert_description = alert_description
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [AccountAlerts]
        def deserialize(data)
          data ||= {}

          new(
            entity_type: data["entity_type"],
            entity_id: data["entity_id"],
            alert_severity: data["alert_severity"],
            alert_status: data["alert_status"],
            alert_description: data["alert_description"]
          )
        end
      end
    end
  end
end
