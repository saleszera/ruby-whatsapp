# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    # Requests a verification code (by SMS or voice call) for a business phone number —
    # the first step of the onboarding flow this module wraps end to end:
    # `RequestCode` -> {VerifyCode} -> {Register}.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/phone-number-verification-request-code-api
    class RequestCode
      include ActiveModel::Validations
      extend ResponseHandling
      extend Transport

      module Defaults
        EDGE = "request_code"
      end

      # How Meta delivers the verification code.
      module CodeMethods
        SMS = "SMS"
        VOICE = "VOICE"

        ALL = [SMS, VOICE].freeze

        # Normalizes caller input to a canonical uppercase code method.
        # Unrecognized values are returned as a string (preserving the original
        # casing) so the inclusion validator can reject them.
        # @param value [String, Symbol, nil]
        # @return [String, nil]
        def self.normalize(value)
          return if value.nil?

          candidate = value.to_s.upcase
          ALL.include?(candidate) ? candidate : value.to_s
        end
      end

      # @!attribute [rw] code_method
      #   @return [String] One of {CodeMethods::ALL}.
      attr_accessor :code_method

      # @!attribute [rw] language
      #   @return [String] The locale for the verification message (e.g. `"en_US"`).
      attr_accessor :language

      validates :code_method, presence: true, inclusion: { in: CodeMethods::ALL }
      validates :language, presence: true

      # @param code_method [String, Symbol] One of {CodeMethods::ALL}, either casing.
      # @param language [String] The locale for the verification message. Meta
      #   publishes no enum for this field, so only presence is checked — unlike
      #   {Register}'s `pin`, which has a documented format.
      # @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(code_method:, language:)
        @code_method = CodeMethods.normalize(code_method)
        @language = language

        validate!
      end

      # @return [Hash] The request-code payload. Both fields are documented required,
      #   so neither is ever compacted away.
      def serialize
        { code_method:, language: }
      end

      class << self
        # @param code_method [String, Symbol] See {#initialize}.
        # @param language [String] See {#initialize}.
        # @param client [Whatsapp::Client] The WhatsApp client instance.
        # @return [Response]
        # @raise [ActiveModel::ValidationError] if the code method or language is invalid.
        # @raise [Error] if no phone number ID is configured, or the request fails.
        def call(code_method:, language:, client: Client.new)
          body = new(code_method:, language:).serialize
          response = client.connection.post(edge_path(client, Defaults::EDGE), json: body)

          Response.deserialize(
            parse_json(handle_response!(response, error_class: Error, action: "request verification code"))
          )
        end
      end
    end
  end
end
