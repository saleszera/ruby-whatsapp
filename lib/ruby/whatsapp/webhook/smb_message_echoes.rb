# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Messages sent via the WhatsApp Business App or a linked device, echoed back
    # so a Cloud API integration stays in sync with what the business itself sent.
    #
    # Best-effort schema: Meta's public docs describe this field in one line with
    # no published JSON example, but do state these mirror the standard inbound
    # `messages` shape — hence reusing {Message.deserialize} here. The exact key
    # name (`message_echoes`) is a best-effort guess; validate against a real
    # payload before relying on it in production.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class SmbMessageEchoes
      # @!attribute [rw] messaging_product
      #   @return [String, nil]
      attr_accessor :messaging_product

      # @!attribute [rw] metadata
      #   @return [Metadata, nil]
      attr_accessor :metadata

      # @!attribute [rw] message_echoes
      #   @return [Array<Message::Base>]
      attr_accessor :message_echoes

      def initialize(messaging_product:, metadata:, message_echoes:)
        @messaging_product = messaging_product
        @metadata = metadata
        @message_echoes = message_echoes
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [SmbMessageEchoes]
        def deserialize(data)
          data ||= {}

          new(
            messaging_product: data["messaging_product"],
            metadata: data["metadata"] ? Metadata.deserialize(data["metadata"]) : nil,
            message_echoes: Array(data["message_echoes"]).map { |echo_data| Message.deserialize(echo_data) }
          )
        end
      end
    end
  end
end
