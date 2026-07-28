# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      class Body < Base
        module Defaults
          MAX_TEXT_LENGTH = 1024
        end

        # @!attribute [rw] text
        #   @return [String]
        attr_accessor :text

        validates :text, presence: true, length: { maximum: Defaults::MAX_TEXT_LENGTH }
        # @param text [String] The footer text.
        def initialize(text)
          @text = text

          validate!
        end

        class << self
          # @return [Hash] Serialized representation of the Header.
          def serialize(text)
            new(text).serialize
          end
        end

        # @return [Hash] Serialized representation of the Header.
        def serialize
          {
            text:,
          }
        end
      end
    end
  end
end
