# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    # Confirms the verification code sent by {RequestCode}, the second step of the
    # onboarding flow this module wraps end to end: {RequestCode} -> `VerifyCode` ->
    # {Register}.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/verify-code-api
    class VerifyCode
      include ActiveModel::Validations
      extend ResponseHandling
      extend Transport

      module Defaults
        EDGE = "verify_code"
      end

      # @!attribute [rw] code
      #   @return [String] The verification code received via SMS or voice call.
      attr_accessor :code

      validates :code, presence: true

      # @param code [String, Integer] The verification code received via SMS or voice
      #   call. Meta documents this as a plain string with no format rule, unlike
      #   {Register}'s `pin`, so only presence is checked.
      # @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(code:)
        @code = code

        validate!
      end

      # @return [Hash] The verify-code payload.
      def serialize
        { code: code.to_s }
      end

      # Redacts the code so it never leaks into logs or console output, same as
      # {Register#inspect} redacts the pin.
      # @return [String]
      def inspect
        "#<#{self.class.name} code=[REDACTED]>"
      end

      class << self
        # @param code [String, Integer] See {#initialize}.
        # @param client [Whatsapp::Client] The WhatsApp client instance.
        # @return [Response]
        # @raise [ActiveModel::ValidationError] if the code is blank.
        # @raise [Error] if no phone number ID is configured, or the request fails.
        def call(code:, client: Client.new)
          body = new(code:).serialize
          response = client.connection.post(edge_path(client, Defaults::EDGE), json: body)

          Response.deserialize(
            parse_json(handle_response!(response, error_class: Error, action: "verify code"))
          )
        end
      end
    end
  end
end
