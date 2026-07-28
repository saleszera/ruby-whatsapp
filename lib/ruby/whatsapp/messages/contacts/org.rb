# frozen_string_literal: true

module Whatsapp
  class Messages
    class Contacts
      # Represents the organization details of a contact message.
      # All fields are optional.
      class Org
        # @!attribute [rw] company
        #   @return [String, nil]
        attr_accessor :company

        # @!attribute [rw] department
        #   @return [String, nil]
        attr_accessor :department

        # @!attribute [rw] title
        #   @return [String, nil]
        attr_accessor :title

        # @param company [String, nil]
        # @param department [String, nil]
        # @param title [String, nil]
        def initialize(company: nil, department: nil, title: nil)
          @company = company
          @department = department
          @title = title
        end

        # @return [Hash] The serialized org payload.
        def serialize
          {
            company:,
            department:,
            title:,
          }.compact
        end
      end
    end
  end
end
