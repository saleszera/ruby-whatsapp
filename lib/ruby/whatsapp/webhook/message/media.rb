# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # Shared shape for the media-backed message types (image, video, audio,
      # document, sticker) — a media asset id you can resolve via {Whatsapp::Media},
      # plus its mime type and content hash.
      class Media < Base
        # @!attribute [rw] media_id
        #   @return [String, nil] The media asset id (resolve via {Whatsapp::Media#url}).
        attr_accessor :media_id

        # @!attribute [rw] mime_type
        #   @return [String, nil]
        attr_accessor :mime_type

        # @!attribute [rw] sha256
        #   @return [String, nil]
        attr_accessor :sha256

        # @!attribute [rw] caption
        #   @return [String, nil]
        attr_accessor :caption

        def initialize(media_id:, mime_type:, sha256:, caption: nil, **base_attributes)
          super(**base_attributes)

          @media_id = media_id
          @mime_type = mime_type
          @sha256 = sha256
          @caption = caption
        end

        class << self
          # Extracts the media-specific fields nested under the given key
          # (e.g. `"image"`, `"video"`), for subclasses to merge with their own
          # extra attributes before calling `new`.
          # @param data [Hash] The raw message hash.
          # @param key [String] The type-specific nested key (e.g. `"image"`).
          # @return [Hash]
          def media_attributes(data, key)
            {
              media_id: data.dig(key, "id"),
              mime_type: data.dig(key, "mime_type"),
              sha256: data.dig(key, "sha256"),
              caption: data.dig(key, "caption"),
            }
          end
        end
      end
    end
  end
end
