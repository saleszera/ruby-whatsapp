# frozen_string_literal: true

module Whatsapp
  class Messages
    class LocationRequest < Base
      module Defaults
        TYPE = "interactive"
        INTERACTIVE_TYPE = "location_request_message"
        ACTION_NAME = "send_location"
      end

      # @!attribute [rw] body
      #   @return [Hash]
      attr_accessor :body

      validates :body, presence: true, length: { maximum: 1024 }

      # @param body [String] The body text of the location request message.
      # @param kwargs [Hash] Additional keyword arguments.
      #  @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(body:, **)
        super(**)

        @body = body

        validate!
      end

      def serialize
        envelope(
          type: Defaults::TYPE,
          interactive: {
            type: Defaults::INTERACTIVE_TYPE,
            body:,
            action: { name: Defaults::ACTION_NAME },
          }
        )
      end
    end
  end
end
