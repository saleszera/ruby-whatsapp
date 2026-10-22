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
          #   @return [String, nil]
          attr_accessor :title

          # @!attribute [rw] rows
          #   @return [Array<Hash>]
          attr_accessor :rows

          # Optional here: Meta requires a title only when the list has more than one
          # section, which a lone Section cannot see — {ListButtons} enforces that rule.
          validates :title, length: { maximum: Defaults::MAX_TITLE_LENGTH }, allow_nil: true
          validates :rows, presence: true, length: { minimum: Defaults::MIN_ROWS_LENGTH, maximum: Defaults::MAX_ROWS_LENGTH }

          # A blank title (`""` or whitespace) is treated as absent, so it is omitted from
          # the payload rather than sent as an empty heading.
          # @param rows [Array<Hash>] The rows in the section.
          # @param title [String, nil] The title of the section. Required only when the list
          #   has more than one section (enforced by {ListButtons}).
          #  @raise [ActiveModel::ValidationError] if validation fails.
          def initialize(rows:, title: nil)
            @title = title.presence
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
            }.compact
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
