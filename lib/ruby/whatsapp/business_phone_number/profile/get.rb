# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module Profile
      # Reads a business profile: its about text, description, contact details, websites,
      # industry vertical, and profile picture.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/whatsapp-business-profile-api
      class Get
        extend ResponseHandling
        extend Transport

        module Defaults
          EDGE = "whatsapp_business_profile"
        end

        # The fields Meta documents for this edge. Offered for convenience, not
        # enforcement — {.call} deliberately does not validate `fields` against this list
        # (nor do {Account::Get} or {Whatsapp::SubscribedApp::List}), so a field Meta adds
        # later works without a gem release.
        module Fields
          MESSAGING_PRODUCT = "messaging_product"
          ABOUT = "about"
          ADDRESS = "address"
          DESCRIPTION = "description"
          EMAIL = "email"
          PROFILE_PICTURE_URL = "profile_picture_url"
          WEBSITES = "websites"
          VERTICAL = "vertical"

          ALL = [MESSAGING_PRODUCT, ABOUT, ADDRESS, DESCRIPTION, EMAIL, PROFILE_PICTURE_URL,
                 WEBSITES, VERTICAL,].freeze
        end

        class << self
          # @example Read everything Meta publishes for the profile
          #   Get.call(fields: Get::Fields::ALL)
          # @param client [Whatsapp::Client] The WhatsApp client instance.
          # @param fields [Array<String>, String, nil] Restrict the response to these
          #   fields; see {Fields::ALL}. Omitted entirely when nil, in which case Meta
          #   returns only its own defaults.
          # @return [Details]
          # @raise [Error] if no phone number ID is configured, or the request fails.
          def call(client: Client.new, fields: nil)
            params = fields ? { fields: Array(fields).join(",") } : {}
            response = client.connection.get(edge_path(client, Defaults::EDGE), params:)

            Details.deserialize(
              parse_json(handle_response!(response, error_class: Error, action: "get business profile details"))
            )
          end
        end
      end
    end
  end
end
