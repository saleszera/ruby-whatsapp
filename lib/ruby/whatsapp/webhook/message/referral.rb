# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # Present when an inbound message originated from a Click-to-WhatsApp ad or a
      # post/story with an embedded WhatsApp link.
      class Referral
        # @!attribute [rw] source_url
        #   @return [String, nil]
        attr_accessor :source_url

        # @!attribute [rw] source_type
        #   @return [String, nil]
        attr_accessor :source_type

        # @!attribute [rw] source_id
        #   @return [String, nil]
        attr_accessor :source_id

        # @!attribute [rw] headline
        #   @return [String, nil]
        attr_accessor :headline

        # @!attribute [rw] body
        #   @return [String, nil]
        attr_accessor :body

        # @!attribute [rw] media_type
        #   @return [String, nil]
        attr_accessor :media_type

        # @!attribute [rw] image_url
        #   @return [String, nil]
        attr_accessor :image_url

        # @!attribute [rw] video_url
        #   @return [String, nil]
        attr_accessor :video_url

        # @!attribute [rw] thumbnail_url
        #   @return [String, nil]
        attr_accessor :thumbnail_url

        def initialize(source_url:, source_type:, source_id:, headline:, body:, media_type:, image_url: nil,
          video_url: nil, thumbnail_url: nil)
          @source_url = source_url
          @source_type = source_type
          @source_id = source_id
          @headline = headline
          @body = body
          @media_type = media_type
          @image_url = image_url
          @video_url = video_url
          @thumbnail_url = thumbnail_url
        end

        class << self
          # @param data [Hash, nil] The raw `referral` hash.
          # @return [Referral, nil]
          def deserialize(data)
            return if data.nil?

            new(
              source_url: data["source_url"],
              source_type: data["source_type"],
              source_id: data["source_id"],
              headline: data["headline"],
              body: data["body"],
              media_type: data["media_type"],
              image_url: data["image_url"],
              video_url: data["video_url"],
              thumbnail_url: data["thumbnail_url"]
            )
          end
        end
      end
    end
  end
end
