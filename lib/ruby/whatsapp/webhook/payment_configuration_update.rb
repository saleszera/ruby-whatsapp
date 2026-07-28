# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Payment configuration changes (India/Brazil).
    #
    # Best-effort schema: Meta's public docs describe this field in one line with
    # no published JSON example. Validate against a real payload (App Dashboard
    # "send test payload") before relying on these attribute names in production.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class PaymentConfigurationUpdate
      # @!attribute [rw] configuration_name
      #   @return [String, nil]
      attr_accessor :configuration_name

      # @!attribute [rw] provider_name
      #   @return [String, nil]
      attr_accessor :provider_name

      # @!attribute [rw] provider_mid
      #   @return [String, nil]
      attr_accessor :provider_mid

      # @!attribute [rw] status
      #   @return [String, nil]
      attr_accessor :status

      def initialize(configuration_name:, provider_name:, provider_mid:, status:)
        @configuration_name = configuration_name
        @provider_name = provider_name
        @provider_mid = provider_mid
        @status = status
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [PaymentConfigurationUpdate]
        def deserialize(data)
          data ||= {}

          new(
            configuration_name: data["configuration_name"],
            provider_name: data["provider_name"],
            provider_mid: data["provider_mid"],
            status: data["status"]
          )
        end
      end
    end
  end
end
