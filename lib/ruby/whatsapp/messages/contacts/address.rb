# frozen_string_literal: true

module Whatsapp
  class Messages
    class Contacts
      # Represents a physical address entry in a contact message.
      # All fields are optional.
      class Address
        include ActiveModel::Validations

        module Types
          HOME = "HOME"
          WORK = "WORK"
          OTHER = "OTHER"

          ALL = [HOME, WORK, OTHER].freeze
        end

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

        validates :type, inclusion: { in: Types::ALL }, allow_nil: true

        # @param street [String, nil]
        # @param city [String, nil]
        # @param state [String, nil]
        # @param zip [String, nil]
        # @param country [String, nil]
        # @param country_code [String, nil] ISO 3166-1 alpha-2 code (e.g. "US").
        # @param type [String, nil] Address type. One of HOME, WORK, OTHER.
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(street: nil, city: nil, state: nil, zip: nil, country: nil, country_code: nil, type: nil)
          @street = street
          @city = city
          @state = state
          @zip = zip
          @country = country
          @country_code = country_code
          @type = type

          validate!
        end

        # @return [Hash] The serialized address payload.
        def serialize
          {
            street:,
            city:,
            state:,
            zip:,
            country:,
            country_code:,
            type:,
          }.compact
        end
      end
    end
  end
end
