# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module Account
      # Reads a WhatsApp Business Account's details: its configuration, review and
      # verification status, and ownership.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/whatsapp-business-account-api
      class Get
        extend ResponseHandling
        extend Transport

        # The fields Meta documents for this node. Offered for convenience, not
        # enforcement — {.call} deliberately does not validate `fields` against this
        # list (nor does {Whatsapp::SubscribedApp::List}), so a field Meta adds later
        # works without a gem release.
        module Fields
          ID = "id"
          NAME = "name"
          TIMEZONE_ID = "timezone_id"
          MESSAGE_TEMPLATE_NAMESPACE = "message_template_namespace"
          ACCOUNT_REVIEW_STATUS = "account_review_status"
          BUSINESS_VERIFICATION_STATUS = "business_verification_status"
          COUNTRY = "country"
          OWNERSHIP_TYPE = "ownership_type"
          PRIMARY_BUSINESS_LOCATION = "primary_business_location"

          ALL = [ID, NAME, TIMEZONE_ID, MESSAGE_TEMPLATE_NAMESPACE, ACCOUNT_REVIEW_STATUS,
                 BUSINESS_VERIFICATION_STATUS, COUNTRY, OWNERSHIP_TYPE, PRIMARY_BUSINESS_LOCATION,].freeze
        end

        class << self
          # @example Read everything Meta publishes for the account
          #   Get.call(fields: Get::Fields::ALL)
          # @param client [Whatsapp::Client] The WhatsApp client instance.
          # @param fields [Array<String>, String, nil] Restrict the response to these
          #   fields; see {Fields::ALL}. Omitted entirely when nil, in which case Meta
          #   returns only its own defaults (`id` and `name`).
          # @return [Details]
          # @raise [Error] if no WABA ID is configured, or the request fails.
          def call(client: Client.new, fields: nil)
            params = fields ? { fields: Array(fields).join(",") } : {}
            response = client.connection.get(node_path(client), params:)

            Details.deserialize(
              parse_json(handle_response!(response, error_class: Error, action: "get business account details"))
            )
          end
        end
      end
    end
  end
end
