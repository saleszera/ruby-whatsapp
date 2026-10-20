# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module Username
      # Removes the business username from a phone number, releasing it.
      #
      # A bare class method with nothing to validate, like {Deregister} and {Profile::Get}:
      # the phone number is the only input and {Transport} already guards it.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
      class Delete
        extend ResponseHandling
        extend Transport

        module Defaults
          EDGE = "username"
        end

        class << self
          # @param client [Whatsapp::Client] The WhatsApp client instance.
          # @return [BusinessPhoneNumber::Response] Reused rather than a `Username::`-specific
          #   class, since this endpoint answers the same bare `{success}` as
          #   {Profile::Update} and {Account::Update}.
          # @raise [Error] if no phone number ID is configured, or the request fails.
          def call(client: Client.new)
            response = client.connection.delete(edge_path(client, Defaults::EDGE))

            BusinessPhoneNumber::Response.deserialize(
              parse_json(handle_response!(response, error_class: Error, action: "delete business username"))
            )
          end
        end
      end
    end
  end
end
