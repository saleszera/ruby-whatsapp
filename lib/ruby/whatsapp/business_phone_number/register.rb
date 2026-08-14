# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    # Registers a business phone number with Cloud API, consuming its two-step
    # verification PIN. This is the prerequisite for every other endpoint in this
    # gem — a number cannot send, receive, or be otherwise addressed until it is
    # registered.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/registration
    class Register
      include ActiveModel::Validations
      extend ResponseHandling
      extend Transport

      module Defaults
        MESSAGING_PRODUCT = "whatsapp"
        EDGE = "register"
        PIN_PATTERN = /\A\d{6}\z/
      end

      # The regions Meta supports for local storage, grouped as Meta's docs group
      # them. 2-letter ISO 3166 country codes.
      module DataLocalizationRegions
        APAC = %w[AU ID IN JP SG KR].freeze
        EUROPE = %w[DE CH GB].freeze
        LATAM = %w[BR].freeze
        MEA = %w[BH ZA AE].freeze
        NORAM = %w[CA].freeze

        ALL = [*APAC, *EUROPE, *LATAM, *MEA, *NORAM].freeze

        # Normalizes caller input to a canonical uppercase region code.
        # Unrecognized values are returned untouched so the inclusion validator can
        # report them.
        # @param value [String, Symbol, nil]
        # @return [String, nil]
        def self.normalize(value)
          return if value.nil?

          candidate = value.to_s.upcase
          ALL.include?(candidate) ? candidate : value.to_s
        end
      end

      # @!attribute [rw] pin
      #   @return [String] The 6-digit two-step verification PIN.
      attr_accessor :pin

      # @!attribute [rw] data_localization_region
      #   @return [String, nil] A 2-letter ISO 3166 country code enabling local storage.
      attr_accessor :data_localization_region

      validate :validate_pin
      validates :data_localization_region, inclusion: { in: DataLocalizationRegions::ALL }, allow_nil: true

      # @param pin [String, Integer] The 6-digit two-step verification PIN. If
      #   two-step verification is already enabled on the number, this must be the
      #   existing PIN.
      # @param data_localization_region [String, Symbol, nil] One of
      #   {DataLocalizationRegions::ALL}, either casing.
      # @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(pin:, data_localization_region: nil)
        @pin = pin
        @data_localization_region = DataLocalizationRegions.normalize(data_localization_region)

        validate!
      end

      # @return [Hash] The registration payload.
      def serialize
        { messaging_product: Defaults::MESSAGING_PRODUCT, pin: pin.to_s, data_localization_region: }.compact
      end

      # Redacts the pin so it never leaks into logs or console output.
      # @return [String]
      def inspect
        "#<#{self.class.name} pin=[REDACTED] data_localization_region=#{data_localization_region.inspect}>"
      end

      class << self
        # @param pin [String, Integer] See {#initialize}.
        # @param client [Whatsapp::Client] The WhatsApp client instance.
        # @param data_localization_region [String, Symbol, nil] See {#initialize}.
        # @return [Response]
        # @raise [ActiveModel::ValidationError] if the pin or region is invalid.
        # @raise [Error] if no phone number ID is configured, or the request fails.
        def call(pin:, client: Client.new, data_localization_region: nil)
          body = new(pin:, data_localization_region:).serialize
          response = client.connection.post(edge_path(client, Defaults::EDGE), json: body)

          Response.deserialize(
            parse_json(handle_response!(response, error_class: Error, action: "register business phone number"))
          )
        end
      end

    private

      # @return [void]
      def validate_pin
        errors.add(:pin, "must be exactly 6 digits") unless pin.to_s.match?(Defaults::PIN_PATTERN)
      end
    end
  end
end
