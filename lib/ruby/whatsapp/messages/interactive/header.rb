# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      class Header < Base
        class HeaderError < Whatsapp::Error; end

        module Types
          IMAGE = "image"
          VIDEO = "video"
          DOCUMENT = "document"
          TEXT = "text"
        end

        # @!attribute [rw] type
        #   @return [String]
        attr_accessor :type

        validates :type, presence: true, inclusion: { in: Types.constants.map { |c| Types.const_get(c) } }
        validate :validate_text_length

        # @param type [String] The type of the header (e.g., "text", "image", "video", "document").
        # @param kwargs [Hash] Additional keyword arguments for the header content.
        def initialize(type:, **kwargs)
          @type = type
          @kwargs = kwargs

          validate!
        end

        class << self
          # @return [Hash] Serialized representation of the Header.
          def serialize(type:, **)
            new(type:, **).serialize
          end
        end

        # @return [Hash] Serialized representation of the Header.
        def serialize
          case type
          when Types::TEXT then serialize_text
          when Types::IMAGE then serialize_image
          when Types::DOCUMENT then serialize_document
          when Types::VIDEO then serialize_video
          else
            raise HeaderError, "Unsupported header type: #{type.inspect}"
          end
        end

      private

        # @return [Hash] Serialized representation of text header.
        def serialize_text
          raise HeaderError, "Text content is required for text header" unless @kwargs[:text]

          {
            type: Types::TEXT,
            text: @kwargs[:text],
          }
        end

        # @return [Hash] Serialized representation of media header.
        def serialize_image
          handle_media(Types::IMAGE)
        end

        # @return [Hash] Serialized representation of media header.
        def serialize_document
          handle_media(Types::DOCUMENT)
        end

        # @return [Hash] Serialized representation of media header.
        def serialize_video
          handle_media(Types::VIDEO)
        end

        # @return [Hash] Serialized representation of media header.
        #  @raise [HeaderError] if required link is missing.
        def handle_media(type)
          raise HeaderError, "#{type.capitalize} link is required for #{type} header" unless @kwargs[:link]

          {
            type:,
            type.to_sym => {
              link: @kwargs[:link],
            },
          }
        end

        # Validates that text headers don't exceed 60 characters
        def validate_text_length
          return unless type == Types::TEXT && @kwargs[:text]

          return unless @kwargs[:text].length > 60

          errors.add(:text, "must be 60 characters or less")
        end
      end
    end
  end
end
