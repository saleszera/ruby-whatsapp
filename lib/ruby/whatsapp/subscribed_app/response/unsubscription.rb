# frozen_string_literal: true

module Whatsapp
  module SubscribedApp
    module Response
      # The response to unsubscribing this app from a WABA's webhook notifications:
      # `{success}`.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/subscribed-apps-api
      class Unsubscription
        # @!attribute [rw] success
        #   @return [Boolean] Whether the app was unsubscribed.
        attr_accessor :success

        # @param success [Boolean]
        def initialize(success: false)
          @success = success
        end

        class << self
          # @param response [Hash, nil] The parsed response body.
          # @return [Unsubscription]
          def deserialize(response)
            response ||= {}

            new(success: response["success"] == true)
          end
        end
      end
    end
  end
end
