# frozen_string_literal: true

module Whatsapp
  module SubscribedApp
    # Unsubscribes this app from a WABA's webhook notifications. All webhook
    # deliveries for that WABA stop immediately.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/subscribed-apps-api
    class Unsubscribe
      extend ResponseHandling
      extend Transport

      class << self
        # @param client [Whatsapp::Client] The WhatsApp client instance.
        # @return [Response::Unsubscription]
        # @raise [Error] if no WABA ID is configured, or the request fails.
        def call(client: Client.new)
          response = client.connection.delete(edge_path(client))

          Response::Unsubscription.deserialize(
            parse_json(handle_response!(response, error_class: Error, action: "unsubscribe app"))
          )
        end
      end
    end
  end
end
