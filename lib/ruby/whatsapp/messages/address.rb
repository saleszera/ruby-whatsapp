# frozen_string_literal: true

module Whatsapp
  class Messages
    # Address messages prompt a WhatsApp user to provide or confirm a delivery address.
    # This feature is only available for businesses based in India (IN) and Singapore (SG).
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/address-messages
    #
    # Despite being a distinct message type in this library, address messages are sent
    # over the wire as interactive messages (type: "interactive", interactive.type: "address_message").
    class Address < Base
      module Defaults
        TYPE = "interactive"
        INTERACTIVE_TYPE = "address_message"
        ACTION_NAME = "address_message"
      end

      module Countries
        IN = "IN"
        SG = "SG"

        ALL = [IN, SG].freeze
      end

      # @!attribute [rw] body
      #   @return [String] The message body text shown above the address form.
      attr_accessor :body

      # @!attribute [rw] footer
      #   @return [String, nil] Optional footer text.
      attr_accessor :footer

      # @!attribute [rw] country
      #   @return [String] Country code. One of IN (India) or SG (Singapore).
      attr_accessor :country

      # @!attribute [rw] values
      #   @return [Hash, nil] Pre-filled address field values shown in the form.
      attr_accessor :values

      # @!attribute [rw] saved_addresses
      #   @return [Array<Hash>] Previously saved addresses the user can select from.
      attr_accessor :saved_addresses

      validates :body, presence: true
      validates :country, presence: true, inclusion: { in: Countries::ALL }

      # @param body [String] The message body text.
      # @param country [String] Country code — "IN" for India, "SG" for Singapore.
      # @param footer [String, nil] Optional footer text.
      # @param values [Hash, nil] Pre-filled address fields (keys vary by country).
      # @param saved_addresses [Array<Hash>] Previously saved addresses.
      # @param kwargs [Hash] Additional keyword arguments passed to Base (:to).
      #  @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(body:, country:, footer: nil, values: nil, saved_addresses: [], **)
        super(**)

        @body = body
        @footer = footer
        @country = country
        @values = values
        @saved_addresses = saved_addresses

        validate!
      end

      # Serializes the address message to a hash format suitable for the WhatsApp API.
      # @return [Hash] The serialized address message.
      def serialize
        envelope(type: Defaults::TYPE, interactive: interactive_payload)
      end

    private

      # @return [Hash] The serialized interactive payload.
      def interactive_payload
        payload = {
          type: Defaults::INTERACTIVE_TYPE,
          body: { text: body },
          action: action_payload,
        }
        payload[:footer] = { text: footer } if footer
        payload
      end

      # @return [Hash] The serialized action payload.
      def action_payload
        {
          name: Defaults::ACTION_NAME,
          parameters: parameters_payload,
        }
      end

      # @return [Hash] The serialized parameters payload.
      def parameters_payload
        params = { country: }
        params[:values] = values if values
        params[:saved_addresses] = saved_addresses if saved_addresses.any?
        params
      end
    end
  end
end
