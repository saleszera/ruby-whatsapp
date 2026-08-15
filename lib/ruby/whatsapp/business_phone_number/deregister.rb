# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    # Deregisters a business phone number from Cloud API. This makes the number
    # unusable with Cloud API and disables local storage — it does not delete the
    # number or its message history.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/phone-number-deregister-api
    class Deregister
      extend ResponseHandling
      extend Transport

      module Defaults
        EDGE = "deregister"
      end

      # Meta documents no parameters for this edge — nothing to validate, so unlike
      # {Register} this class carries no attributes and no `ActiveModel::Validations`.
      # @return [Hash] Always empty.
      def serialize
        {}
      end

      class << self
        # @param client [Whatsapp::Client] The WhatsApp client instance.
        # @return [Response]
        # @raise [Error] if no phone number ID is configured, or the request fails.
        def call(client: Client.new)
          response = client.connection.post(edge_path(client, Defaults::EDGE), json: new.serialize)

          Response.deserialize(
            parse_json(handle_response!(response, error_class: Error, action: "deregister business phone number"))
          )
        end
      end
    end
  end
end
