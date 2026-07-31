# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Verifies the `X-Hub-Signature-256` header Meta attaches to every webhook POST,
    # an HMAC-SHA256 of the raw request body keyed by the app secret.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class Signature
      PREFIX = "sha256="

      class << self
        # @param payload [String] The raw (unparsed) request body.
        # @param header [String, nil] The `X-Hub-Signature-256` header value.
        # @param app_secret [String, nil] The secret to verify against. Defaults to the
        #   globally configured secret; pass an explicit value for multi-tenant apps where
        #   each account has its own Meta App (and therefore its own secret).
        # @return [Boolean] Whether the header matches the computed signature.
        def valid?(payload:, header:, app_secret: Whatsapp.configuration.app_secret)
          return false if header.nil? || header.empty?
          return false if app_secret.nil? || app_secret.empty?

          expected = PREFIX + OpenSSL::HMAC.hexdigest("SHA256", app_secret, payload)
          ActiveSupport::SecurityUtils.secure_compare(expected, header)
        end
      end
    end
  end
end
