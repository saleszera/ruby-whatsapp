# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      class ListButtons
        class Section
          class Row
            include ActiveModel::Validations

            module Defaults
              MAX_ID_LENGTH = 200
              MAX_TITLE_LENGTH = 24
              MAX_DESCRIPTION_LENGTH = 72
            end

            # @!attribute [rw] id
            #   @return [String]
            attr_accessor :id

            # @!attribute [rw] title
            #   @return [String]
            attr_accessor :title

            # @!attribute [rw] description
            #   @return [String, nil]
            attr_accessor :description

            validates :id, presence: true, length: { maximum: Defaults::MAX_ID_LENGTH }
            validates :title, presence: true, length: { maximum: Defaults::MAX_TITLE_LENGTH }
            validates :description, length: { maximum: Defaults::MAX_DESCRIPTION_LENGTH }, allow_nil: true

            # @param id [String] The unique identifier for the row.
            # @param title [String] The title of the row.
            # @param description [String, nil] The description of the row.
            #  @raise [ActiveModel::ValidationError] if validation fails.
            def initialize(id:, title:, description: nil)
              @id = id
              @title = title
              @description = description

              validate!
            end

            class << self
              # @return [Hash] Serialized representation of the Row.
              #  @raise [ActiveModel::ValidationError] if validation fails.
              def serialize(**row)
                new(**row).serialize
              end
            end

            # @return [Hash] Serialized representation of the Row.
            def serialize
              {
                id:,
                title:,
                description:,
              }.compact
            end
          end
        end
      end
    end
  end
end
