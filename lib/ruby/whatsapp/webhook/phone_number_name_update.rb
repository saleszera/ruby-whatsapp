# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Display name verification outcomes for a business phone number.
    #
    # Best-effort schema: Meta's public docs describe this field in one line with
    # no published JSON example. Validate against a real payload (App Dashboard
    # "send test payload") before relying on these attribute names in production.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class PhoneNumberNameUpdate
      # @!attribute [rw] phone_number
      #   @return [String, nil]
      attr_accessor :phone_number

      # @!attribute [rw] decision
      #   @return [String, nil] e.g. `"APPROVED"`, `"REJECTED"`.
      attr_accessor :decision

      # @!attribute [rw] requested_verified_name
      #   @return [String, nil]
      attr_accessor :requested_verified_name

      # @!attribute [rw] rejection_reason
      #   @return [String, nil]
      attr_accessor :rejection_reason

      def initialize(phone_number:, decision:, requested_verified_name:, rejection_reason: nil)
        @phone_number = phone_number
        @decision = decision
        @requested_verified_name = requested_verified_name
        @rejection_reason = rejection_reason
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [PhoneNumberNameUpdate]
        def deserialize(data)
          data ||= {}

          new(
            phone_number: data["phone_number"],
            decision: data["decision"],
            requested_verified_name: data["requested_verified_name"],
            rejection_reason: data["rejection_reason"]
          )
        end
      end
    end
  end
end
