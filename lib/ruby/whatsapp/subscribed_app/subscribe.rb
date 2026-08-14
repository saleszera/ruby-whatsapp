# frozen_string_literal: true

module Whatsapp
  module SubscribedApp
    # Subscribes this app to a WABA's webhook notifications.
    #
    # `override_callback_uri`/`verify_token` are for Tech Providers routing several
    # WABAs' notifications to different callback URLs instead of the one configured on
    # the app itself.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/subscribed-apps-api
    class Subscribe
      extend ResponseHandling
      extend Transport

      class << self
        # @param client [Whatsapp::Client] The WhatsApp client instance.
        # @param override_callback_uri [String, nil] A per-WABA webhook callback override.
        # @param verify_token [String, nil] The token Meta echoes back if it re-verifies
        #   `override_callback_uri`.
        # @return [Response::Subscription]
        # @raise [Error] if no WABA ID is configured, or the request fails.
        def call(client: Client.new, override_callback_uri: nil, verify_token: nil)
          body = { override_callback_uri:, verify_token: }.compact
          response = client.connection.post(edge_path(client), json: body)

          Response::Subscription.deserialize(
            parse_json(handle_response!(response, error_class: Error, action: "subscribe app"))
          )
        end
      end
    end
  end
end
