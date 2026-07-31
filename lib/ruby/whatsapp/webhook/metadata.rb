# frozen_string_literal: true

module Whatsapp
  module Webhook
    # The `metadata` object present on most webhook `value` payloads, identifying
    # which of your business phone numbers the notification is about.
    class Metadata
      # @!attribute [rw] display_phone_number
      #   @return [String, nil]
      attr_accessor :display_phone_number

      # @!attribute [rw] phone_number_id
      #   @return [String, nil]
      attr_accessor :phone_number_id

      def initialize(display_phone_number:, phone_number_id:)
        @display_phone_number = display_phone_number
        @phone_number_id = phone_number_id
      end

      class << self
        # @param data [Hash] The raw `metadata` hash.
        # @return [Metadata]
        def deserialize(data)
          data ||= {}

          new(
            display_phone_number: data["display_phone_number"],
            phone_number_id: data["phone_number_id"]
          )
        end
      end
    end
  end
end
