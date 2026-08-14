# frozen_string_literal: true

module Whatsapp
  module SubscribedApp
    module Response
      # The response to subscribing this app to a WABA's webhook notifications:
      # `{success, data}`.
      #
      # `data` mirrors {Collection}'s shape exactly, since Meta echoes back every app
      # now subscribed — deserialization is delegated to {Collection.deserialize}
      # rather than duplicating the `App` mapping.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/subscribed-apps-api
      class Subscription
        include Enumerable

        # @!attribute [rw] success
        #   @return [Boolean] Whether the subscription succeeded.
        attr_accessor :success

        # @!attribute [rw] data
        #   @return [Array<App>]
        attr_accessor :data

        # @param success [Boolean]
        # @param data [Array<App>]
        def initialize(success: false, data: [])
          @success = success
          @data = data
        end

        class << self
          # @param response [Hash, nil] The parsed response body.
          # @return [Subscription]
          def deserialize(response)
            response ||= {}

            new(success: response["success"] == true, data: Collection.deserialize(response).to_a)
          end
        end

        # @yieldparam app [App]
        # @return [Enumerator]
        def each(&)
          data.each(&)
        end
      end
    end
  end
end
