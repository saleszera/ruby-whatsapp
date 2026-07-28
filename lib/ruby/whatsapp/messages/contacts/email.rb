# frozen_string_literal: true

module Whatsapp
  class Messages
    class Contacts
      # Represents an email entry in a contact message.
      class Email
        include ActiveModel::Validations

        module Types
          HOME = "HOME"
          WORK = "WORK"
          OTHER = "OTHER"

          ALL = [HOME, WORK, OTHER].freeze
        end

        # @!attribute [rw] email
        #   @return [String]
        attr_accessor :email

        # @!attribute [rw] type
        #   @return [String, nil]
        attr_accessor :type

        validates :email, presence: true
        validates :type, inclusion: { in: Types::ALL }, allow_nil: true

        # @param email [String] The email address.
        # @param type [String, nil] Email type. One of HOME, WORK, OTHER.
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(email:, type: nil)
          @email = email
          @type = type

          validate!
        end

        # @return [Hash] The serialized email payload.
        def serialize
          {
            email:,
            type:,
          }.compact
        end
      end
    end
  end
end
