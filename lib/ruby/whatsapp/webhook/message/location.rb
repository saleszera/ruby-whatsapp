# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # An inbound shared location.
      class Location < Base
        # @!attribute [rw] latitude
        #   @return [Float, nil]
        attr_accessor :latitude

        # @!attribute [rw] longitude
        #   @return [Float, nil]
        attr_accessor :longitude

        # @!attribute [rw] name
        #   @return [String, nil]
        attr_accessor :name

        # @!attribute [rw] address
        #   @return [String, nil]
        attr_accessor :address

        def initialize(latitude:, longitude:, name: nil, address: nil, **base_attributes)
          super(**base_attributes)

          @latitude = latitude
          @longitude = longitude
          @name = name
          @address = address
        end

        class << self
          # @param data [Hash] The raw message hash.
          # @return [Location]
          def deserialize(data)
            new(
              latitude: data.dig("location", "latitude"),
              longitude: data.dig("location", "longitude"),
              name: data.dig("location", "name"),
              address: data.dig("location", "address"),
              **common_attributes(data)
            )
          end
        end
      end
    end
  end
end
