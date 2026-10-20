# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module Username
      # Lists the usernames Meta has reserved for your business portfolio.
      #
      # Named for the verb, like {Register}/{Subscribe}, leaving the noun {Suggestions} to
      # the value object it returns. The one action here addressing the
      # `username_suggestions` edge rather than `username`.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
      class Suggest
        extend ResponseHandling
        extend Transport

        module Defaults
          EDGE = "username_suggestions"
        end

        class << self
          # @example Claim the first name Meta reserved for you
          #   Username::Claim.call(username: Username::Suggest.call.first)
          # @param client [Whatsapp::Client] The WhatsApp client instance.
          # @return [Suggestions] Enumerable over the reserved usernames; empty if none.
          # @raise [Error] if no phone number ID is configured, or the request fails.
          def call(client: Client.new)
            response = client.connection.get(edge_path(client, Defaults::EDGE))

            Suggestions.deserialize(
              parse_json(handle_response!(response, error_class: Error, action: "get username suggestions"))
            )
          end
        end
      end
    end
  end
end
