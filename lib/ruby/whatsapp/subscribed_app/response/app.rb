# frozen_string_literal: true

module Whatsapp
  module SubscribedApp
    module Response
      # One app subscribed to a WABA's webhook notifications.
      #
      # Meta nests `id`/`name`/`link` inside `whatsapp_business_api_data`; this class
      # flattens that away since the wrapper carries no information of its own.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/subscribed-apps-api
      class App
        # @!attribute [rw] id
        #   @return [String, nil] The subscribed app's ID.
        attr_accessor :id

        # @!attribute [rw] name
        #   @return [String, nil] The subscribed app's name.
        attr_accessor :name

        # @!attribute [rw] link
        #   @return [String, nil] A link to the app.
        attr_accessor :link

        # @!attribute [rw] override_callback_uri
        #   @return [String, nil] The per-WABA webhook callback override, if one is set.
        attr_accessor :override_callback_uri

        # @param id [String, nil]
        # @param name [String, nil]
        # @param link [String, nil]
        # @param override_callback_uri [String, nil]
        def initialize(id: nil, name: nil, link: nil, override_callback_uri: nil)
          @id = id
          @name = name
          @link = link
          @override_callback_uri = override_callback_uri
        end

        class << self
          # @param data [Hash, nil] One element of the `data` array.
          # @return [App]
          def deserialize(data)
            data ||= {}
            api_data = data["whatsapp_business_api_data"] || {}

            new(
              id: api_data["id"],
              name: api_data["name"],
              link: api_data["link"],
              override_callback_uri: data["override_callback_uri"]
            )
          end
        end
      end
    end
  end
end
