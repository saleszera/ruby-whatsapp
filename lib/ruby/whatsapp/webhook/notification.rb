# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Top-level deserialization entry point for an incoming webhook POST body.
    # @example
    #   Whatsapp::Webhook::Notification.deserialize(JSON.parse(request.body.read))
    class Notification
      # @!attribute [rw] object
      #   @return [String]
      attr_accessor :object

      # @!attribute [rw] entry
      #   @return [Array<Entry>]
      attr_accessor :entry

      def initialize(object:, entry:)
        @object = object
        @entry = entry
      end

      class << self
        # @param data [Hash] The parsed JSON request body.
        # @return [Notification]
        def deserialize(data)
          data ||= {}

          new(
            object: data["object"],
            entry: Array(data["entry"]).map { |entry_data| Entry.deserialize(entry_data) }
          )
        end
      end
    end
  end
end
