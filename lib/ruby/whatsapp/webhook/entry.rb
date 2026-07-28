# frozen_string_literal: true

module Whatsapp
  module Webhook
    # A single `entry[]` item — one WhatsApp Business Account, with one or more
    # `changes[]` (each a distinct notification).
    class Entry
      # @!attribute [rw] id
      #   @return [String]
      attr_accessor :id

      # @!attribute [rw] changes
      #   @return [Array<Change>]
      attr_accessor :changes

      def initialize(id:, changes:)
        @id = id
        @changes = changes
      end

      class << self
        # @param data [Hash] A raw `entry[]` item.
        # @return [Entry]
        def deserialize(data)
          data ||= {}

          new(
            id: data["id"],
            changes: Array(data["changes"]).map { |change_data| Change.deserialize(change_data) }
          )
        end
      end
    end
  end
end
