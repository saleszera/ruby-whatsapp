# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      class ReplyButtons
        class Button
          include ActiveModel::Validations

          module Defaults
            TYPE = "reply"
            MAX_ID_LENGTH = 256
            MAX_TITLE_LENGTH = 20
          end

          # @!attribute [rw] id
          #   @return [String]
          attr_accessor :id

          # @!attribute [rw] title
          #   @return [String]
          attr_accessor :title

          validates :id, presence: true, length: { maximum: Defaults::MAX_ID_LENGTH }
          validates :title, presence: true, length: { maximum: Defaults::MAX_TITLE_LENGTH }

          # @param id [String] The ID of the button.
          # @param title [String] The title of the button.
          #  @raise [ActiveModel::ValidationError] if validation fails.
          def initialize(id:, title:)
            @id = id
            @title = title

            validate!
          end

          class << self
            # @return [Hash] Serialized representation of the Button.
            #  @raise [ActiveModel::ValidationError] if validation fails.
            def serialize(id:, title:)
              new(id:, title:).serialize
            end
          end

          # @return [Hash] Serialized representation of the Button.
          def serialize
            {
              type: Defaults::TYPE,
              reply: {
                id:,
                title:,
              },
            }
          end
        end
      end
    end
  end
end
