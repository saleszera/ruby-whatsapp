# frozen_string_literal: true

module Whatsapp
  module Webhook
    # An error entry, present on message/status payloads that couldn't be fully
    # processed (e.g. an unsupported message type, or a failed delivery).
    class Error
      # @!attribute [rw] code
      #   @return [Integer, nil]
      attr_accessor :code

      # @!attribute [rw] title
      #   @return [String, nil]
      attr_accessor :title

      # @!attribute [rw] message
      #   @return [String, nil]
      attr_accessor :message

      # @!attribute [rw] details
      #   @return [String, nil]
      attr_accessor :details

      def initialize(code:, title:, message:, details: nil)
        @code = code
        @title = title
        @message = message
        @details = details
      end

      class << self
        # @param data [Hash] A raw `errors[]` entry.
        # @return [Error]
        def deserialize(data)
          data ||= {}

          new(
            code: data["code"],
            title: data["title"],
            message: data["message"],
            details: data.dig("error_data", "details")
          )
        end
      end
    end
  end
end
