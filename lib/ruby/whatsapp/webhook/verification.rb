# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Handles the one-time GET handshake Meta sends when a webhook callback URL is
    # registered in the App Dashboard: `hub.mode`, `hub.verify_token`, `hub.challenge`.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class Verification
      class << self
        # @param params [Hash] The request params, string-keyed as Rails provides them
        #   (e.g. `params["hub.mode"]`, `params["hub.verify_token"]`, `params["hub.challenge"]`).
        # @param verify_token [String, nil] The token to check against. Defaults to the
        #   globally configured token; pass an explicit value for multi-tenant apps where
        #   each account has its own token.
        # @return [String, nil] The `hub.challenge` value to echo back, or `nil` if the
        #   request doesn't match a subscribe handshake with the expected token.
        def call(params:, verify_token: Whatsapp.configuration.verify_token)
          return unless params["hub.mode"] == "subscribe"
          return if verify_token.nil? || verify_token.empty?
          return unless ActiveSupport::SecurityUtils.secure_compare(params["hub.verify_token"].to_s, verify_token)

          params["hub.challenge"]
        end
      end
    end
  end
end
