# frozen_string_literal: true

module Whatsapp
  class Messages
    class Contacts
      # Represents a phone number entry in a contact message.
      class Phone
        include ActiveModel::Validations

        module Types
          CELL = "CELL"
          MAIN = "MAIN"
          IPHONE = "IPHONE"
          HOME = "HOME"
          WORK = "WORK"
          OTHER = "OTHER"

          ALL = [CELL, MAIN, IPHONE, HOME, WORK, OTHER].freeze
        end

        # @!attribute [rw] phone
        #   @return [String]
        attr_accessor :phone

        # @!attribute [rw] type
        #   @return [String, nil]
        attr_accessor :type

        # @!attribute [rw] wa_id
        #   @return [String, nil]
        attr_accessor :wa_id

        validates :phone, presence: true
        validates :type, inclusion: { in: Types::ALL }, allow_nil: true

        # @param phone [String] The phone number, including country code.
        # @param type [String, nil] Phone type. One of CELL, MAIN, IPHONE, HOME, WORK, OTHER.
        # @param wa_id [String, nil] The WhatsApp ID for this phone number.
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(phone:, type: nil, wa_id: nil)
          @phone = phone
          @type = type
          @wa_id = wa_id

          validate!
        end

        # @return [Hash] The serialized phone payload.
        def serialize
          {
            phone:,
            type:,
            wa_id:,
          }.compact
        end
      end
    end
  end
end
