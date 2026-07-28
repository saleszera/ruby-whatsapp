# frozen_string_literal: true

module Whatsapp
  class Messages
    # Location messages allow you to send a location's latitude and longitude coordinates to a WhatsApp user.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/location-messages
    class Location < Base
      module Defaults
        TYPE = "location"
      end

      # @!attribute [rw] latitude
      #   @return [Float]
      attr_accessor :latitude

      # @!attribute [rw] longitude
      #   @return [Float]
      attr_accessor :longitude

      # @!attribute [rw] name
      #   @return [String, nil]
      attr_accessor :name

      # @!attribute [rw] address
      #   @return [String, nil]
      attr_accessor :address

      validates :latitude, presence: true, numericality: true
      validates :longitude, presence: true, numericality: true

      # @param latitude [Float] The latitude of the location.
      # @param longitude [Float] The longitude of the location.
      # @param name [String, nil] The name of the location.
      # @param address [String, nil] The address of the location.
      # @param kwargs [Hash] Additional keyword arguments (e.g. :to).
      #  @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(latitude:, longitude:, name: nil, address: nil, **)
        super(**)

        @latitude = latitude
        @longitude = longitude
        @name = name
        @address = address

        validate!
      end

      # Serializes the location message to a hash format suitable for the WhatsApp API.
      # @return [Hash] The serialized location message.
      def serialize
        envelope(type: Defaults::TYPE, location: location_payload)
      end

    private

      # @return [Hash] The serialized location information.
      def location_payload
        {
          latitude:,
          longitude:,
          name:,
          address:,
        }.compact
      end
    end
  end
end
