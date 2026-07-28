# frozen_string_literal: true

module Whatsapp
  class Messages
    class Template
      # Parameters for template components
      class Parameter
        include ActiveModel::Validations

        module Types
          TEXT = "text"
          CURRENCY = "currency"
          DATE_TIME = "date_time"
          IMAGE = "image"
          DOCUMENT = "document"
          VIDEO = "video"
          LOCATION = "location"
          PAYLOAD = "payload"
        end

        # @!attribute [rw] type
        #   @return [String]
        attr_accessor :type

        # @!attribute [rw] text
        #   @return [String, nil]
        attr_accessor :text

        # @!attribute [rw] currency
        #   @return [Hash, nil]
        attr_accessor :currency

        # @!attribute [rw] date_time
        #   @return [Hash, nil]
        attr_accessor :date_time

        # @!attribute [rw] image
        #   @return [Hash, nil]
        attr_accessor :image

        # @!attribute [rw] document
        #   @return [Hash, nil]
        attr_accessor :document

        # @!attribute [rw] video
        #   @return [Hash, nil]
        attr_accessor :video

        # @!attribute [rw] location
        #   @return [Hash, nil]
        attr_accessor :location

        # @!attribute [rw] payload
        #   @return [String, nil]
        attr_accessor :payload

        validates :type, presence: true, inclusion: { in: Types.constants.map { |c| Types.const_get(c) } }

        # @param type [String] The parameter type (one of Types: text, currency, date_time,
        #   image, document, video, location, payload).
        # @param text [String, nil] The text value for text parameters.
        # @param currency [Hash, nil] Currency details for currency parameters.
        # @param date_time [Hash, nil] Date/time details for date_time parameters.
        # @param image [Hash, nil] Image details for image parameters.
        # @param document [Hash, nil] Document details for document parameters.
        # @param video [Hash, nil] Video details for video parameters.
        # @param location [Hash, nil] Location details for location parameters.
        # @param payload [String, nil] Payload for button parameters.
        def initialize(type:, text: nil, currency: nil, date_time: nil, image: nil, document: nil, video: nil,
          location: nil, payload: nil)
          @type = type
          @text = text
          @currency = currency
          @date_time = date_time
          @image = image
          @document = document
          @video = video
          @location = location
          @payload = payload

          validate!
        end

        # Serializes the parameter to a hash format suitable for the WhatsApp API.
        # @return [Hash] The serialized parameter.
        def serialize
          result = { type: }

          case type
          when Types::TEXT
            result[:text] = text
          when Types::CURRENCY
            result[:currency] = currency
          when Types::DATE_TIME
            result[:date_time] = date_time
          when Types::IMAGE
            result[:image] = image
          when Types::DOCUMENT
            result[:document] = document
          when Types::VIDEO
            result[:video] = video
          when Types::LOCATION
            result[:location] = location
          when Types::PAYLOAD
            result[:payload] = payload
          end

          result.compact
        end
      end
    end
  end
end
