# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Policy guideline review outcomes for WhatsApp Business Accounts.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class AccountReviewUpdate
      # @!attribute [rw] decision
      #   @return [String, nil] e.g. `"APPROVED"`, `"REJECTED"`.
      attr_accessor :decision

      def initialize(decision:)
        @decision = decision
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [AccountReviewUpdate]
        def deserialize(data)
          data ||= {}

          new(decision: data["decision"])
        end
      end
    end
  end
end
