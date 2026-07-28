# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      class ListButtons
        class Section
          include ActiveModel::Validations

          module Defaults
            MAX_TITLE_LENGTH = 24
            MIN_ROWS_LENGTH = 1
            MAX_ROWS_LENGTH = 10
          end

          # @!attribute [rw] title
          #   @return [String]
          attr_accessor :title

          # @!attribute [rw] rows
          #   @return [Array<Hash>]
          attr_accessor :rows

          validates :title, presence: true, length: { maximum: Defaults::MAX_TITLE_LENGTH }
          validates :rows, presence: true, length: { minimum: Defaults::MIN_ROWS_LENGTH, maximum: Defaults::MAX_ROWS_LENGTH }

          # @param title [String] The title of the section.
          # @param rows [Array<Hash>] The rows in the section.
          #  @raise [ActiveModel::ValidationError] if validation fails.
          def initialize(title:, rows:)
            @title = title
            @rows = rows

            validate!
          end

          class << self
            # @return [Hash] Serialized representation of the Section.
            #  @raise [ActiveModel::ValidationError] if validation fails.
            def serialize(**section)
              new(**section).serialize
            end
          end

          # @return [Hash] Serialized representation of the Section.
          def serialize
            {
              title:,
              rows: serialized_rows,
            }
          end

        private

          # @return [Array<Hash>] Serialized rows.
          #  @raise [ActiveModel::ValidationError] if validation fails.
          def serialized_rows
            rows.map { |row| Row.serialize(**row) }
          end
        end
      end
    end
  end
end
