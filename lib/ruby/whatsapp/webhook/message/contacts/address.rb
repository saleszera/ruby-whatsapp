# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      class Contacts < Base
        # A physical address entry within an inbound contact card.
        class Address
          # @!attribute [rw] street
          #   @return [String, nil]
          attr_accessor :street

          # @!attribute [rw] city
          #   @return [String, nil]
          attr_accessor :city

          # @!attribute [rw] state
          #   @return [String, nil]
          attr_accessor :state

          # @!attribute [rw] zip
          #   @return [String, nil]
          attr_accessor :zip

          # @!attribute [rw] country
          #   @return [String, nil]
          attr_accessor :country

          # @!attribute [rw] country_code
          #   @return [String, nil]
          attr_accessor :country_code

          # @!attribute [rw] type
          #   @return [String, nil]
          attr_accessor :type

          def initialize(street: nil, city: nil, state: nil, zip: nil, country: nil, country_code: nil, type: nil)
            @street = street
            @city = city
            @state = state
            @zip = zip
            @country = country
            @country_code = country_code
            @type = type
          end

          class << self
            # @param data [Hash] A raw `addresses[]` entry.
            # @return [Address]
            def deserialize(data)
              data ||= {}

              new(
                street: data["street"],
                city: data["city"],
                state: data["state"],
                zip: data["zip"],
                country: data["country"],
                country_code: data["country_code"],
                type: data["type"]
              )
            end
          end
        end
      end
    end
  end
end
