# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    # The response to registering or deregistering a business phone number:
    # `{success}`. Both edges return this identical shape, so unlike
    # {Whatsapp::SubscribedApp}'s `Response::*` namespace, one class covers both
    # {Register} and {Deregister}.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/registration
    class Response
      # @!attribute [rw] success
      #   @return [Boolean] Whether the number was registered or deregistered.
      attr_accessor :success

      # @param success [Boolean]
      def initialize(success: false)
        @success = success
      end

      class << self
        # @param response [Hash, nil] The parsed response body.
        # @return [Response]
        def deserialize(response)
          response ||= {}

          new(success: response["success"] == true)
        end
      end
    end
  end
end
