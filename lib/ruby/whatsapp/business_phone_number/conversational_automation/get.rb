# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module ConversationalAutomation
      # Reads the conversational components configured on a phone number.
      #
      # Meta exposes this read as a *field* on the phone number node
      # (`GET /{phone_id}?fields=conversational_automation`), not as a `GET` on the edge
      # {Update} posts to — so this is the one caller of {Transport#node_path}. No `fields:`
      # parameter: the field is the whole endpoint. A pure class method with nothing to
      # validate, like {Profile::Get}.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/conversational-components
      class Get
        extend ResponseHandling
        extend Transport

        module Defaults
          FIELDS = "conversational_automation"
        end

        class << self
          # @example
          #   Get.call.prompts # => ["Book a flight", "Plan a vacation"]
          # @param client [Whatsapp::Client] The WhatsApp client instance.
          # @return [Details]
          # @raise [Error] if no phone number ID is configured, or the request fails.
          def call(client: Client.new)
            response = client.connection.get(node_path(client), params: { fields: Defaults::FIELDS })

            Details.deserialize(
              parse_json(handle_response!(response, error_class: Error, action: "get conversational automation"))
            )
          end
        end
      end
    end
  end
end
