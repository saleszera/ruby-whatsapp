# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Template status modifications — approved, rejected, flagged, paused, or
    # disabled by Meta.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class MessageTemplateStatusUpdate
      # @!attribute [rw] message_template_id
      #   @return [Integer, nil]
      attr_accessor :message_template_id

      # @!attribute [rw] message_template_name
      #   @return [String, nil]
      attr_accessor :message_template_name

      # @!attribute [rw] message_template_language
      #   @return [String, nil]
      attr_accessor :message_template_language

      # @!attribute [rw] event
      #   @return [String, nil] e.g. `"APPROVED"`, `"REJECTED"`, `"FLAGGED"`, `"PAUSED"`, `"DISABLED"`.
      attr_accessor :event

      # @!attribute [rw] reason
      #   @return [String, nil]
      attr_accessor :reason

      def initialize(message_template_id:, message_template_name:, message_template_language:, event:, reason: nil)
        @message_template_id = message_template_id
        @message_template_name = message_template_name
        @message_template_language = message_template_language
        @event = event
        @reason = reason
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [MessageTemplateStatusUpdate]
        def deserialize(data)
          data ||= {}

          new(
            message_template_id: data["message_template_id"],
            message_template_name: data["message_template_name"],
            message_template_language: data["message_template_language"],
            event: data["event"],
            reason: data["reason"]
          )
        end
      end
    end
  end
end
