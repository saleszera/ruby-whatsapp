# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module Username
      # Reads the business username currently on a phone number, and its status.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
      class Get
        extend ResponseHandling
        extend Transport

        module Defaults
          EDGE = "username"
        end

        class << self
          # @example Check whether the username is live yet
          #   Get.call.approved?  # => false, while still `reserved`
          # @param client [Whatsapp::Client] The WhatsApp client instance.
          # @return [Details] Whose `username` is `nil` if the number has none set.
          # @raise [Error] if no phone number ID is configured, or the request fails.
          def call(client: Client.new)
            response = client.connection.get(edge_path(client, Defaults::EDGE))

            Details.deserialize(
              parse_json(handle_response!(response, error_class: Error, action: "get business username"))
            )
          end
        end
      end
    end
  end
end
