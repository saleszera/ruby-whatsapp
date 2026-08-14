# frozen_string_literal: true

module Whatsapp
  module SubscribedApp
    # Lists the apps currently subscribed to a WABA's webhook notifications.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/subscribed-apps-api
    class List
      extend ResponseHandling
      extend Transport

      class << self
        # @param client [Whatsapp::Client] The WhatsApp client instance.
        # @param fields [Array<String>, String, nil] Restrict each app to these fields
        #   (`id`, `name`, `link`).
        # @return [Response::Collection]
        # @raise [Error] if no WABA ID is configured, or the request fails.
        def call(client: Client.new, fields: nil)
          params = fields ? { fields: Array(fields).join(",") } : {}
          response = client.connection.get(edge_path(client), params:)

          Response::Collection.deserialize(
            parse_json(handle_response!(response, error_class: Error, action: "list subscribed apps"))
          )
        end
      end
    end
  end
end
