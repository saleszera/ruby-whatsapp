# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    # The response shared by all five actions in this module: `{success}`, with an
    # optional `id` that only `VerifyCode` ever populates. One class covers all of
    # them — unlike {Whatsapp::SubscribedApp}'s `Response::*` namespace — since
    # {Register}, {Deregister}, {RequestCode}, {VerifyCode}, and {Account::Update} all
    # return this same shape, `id` included or not.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/registration
    class Response
      # @!attribute [rw] success
      #   @return [Boolean] Whether the action succeeded.
      attr_accessor :success

      # @!attribute [rw] id
      #   @return [String, nil] The phone number ID, only ever present on
      #     {VerifyCode}'s response.
      attr_accessor :id

      # @param success [Boolean]
      # @param id [String, nil]
      def initialize(success: false, id: nil)
        @success = success
        @id = id
      end

      class << self
        # @param response [Hash, nil] The parsed response body.
        # @return [Response]
        def deserialize(response)
          response ||= {}

          new(success: response["success"] == true, id: response["id"])
        end
      end
    end
  end
end
