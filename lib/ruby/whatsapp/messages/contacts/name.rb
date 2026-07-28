# frozen_string_literal: true

module Whatsapp
  class Messages
    class Contacts
      # Represents the name component of a contact message.
      class Name
        include ActiveModel::Validations

        # @!attribute [rw] formatted_name
        #   @return [String] The contact's full display name. Required.
        attr_accessor :formatted_name

        # @!attribute [rw] first_name
        #   @return [String, nil]
        attr_accessor :first_name

        # @!attribute [rw] last_name
        #   @return [String, nil]
        attr_accessor :last_name

        # @!attribute [rw] middle_name
        #   @return [String, nil]
        attr_accessor :middle_name

        # @!attribute [rw] prefix
        #   @return [String, nil]
        attr_accessor :prefix

        # @!attribute [rw] suffix
        #   @return [String, nil]
        attr_accessor :suffix

        validates :formatted_name, presence: true

        # @param formatted_name [String] The contact's full display name.
        # @param first_name [String, nil]
        # @param last_name [String, nil]
        # @param middle_name [String, nil]
        # @param prefix [String, nil]
        # @param suffix [String, nil]
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(formatted_name:, first_name: nil, last_name: nil, middle_name: nil, prefix: nil, suffix: nil)
          @formatted_name = formatted_name
          @first_name = first_name
          @last_name = last_name
          @middle_name = middle_name
          @prefix = prefix
          @suffix = suffix

          validate!
        end

        # @return [Hash] The serialized name payload.
        def serialize
          {
            formatted_name:,
            first_name:,
            last_name:,
            middle_name:,
            prefix:,
            suffix:,
          }.compact
        end
      end
    end
  end
end
