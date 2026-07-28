# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Template component modifications (e.g. Meta editing a template's header,
    # body, or button on the business's behalf).
    #
    # Best-effort schema: Meta's public docs describe this field in one line with
    # no published JSON example. Validate against a real payload (App Dashboard
    # "send test payload") before relying on these attribute names in production.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class MessageTemplateComponentsUpdate
      # @!attribute [rw] message_template_id
      #   @return [Integer, nil]
      attr_accessor :message_template_id

      # @!attribute [rw] message_template_name
      #   @return [String, nil]
      attr_accessor :message_template_name

      # @!attribute [rw] message_template_language
      #   @return [String, nil]
      attr_accessor :message_template_language

      # @!attribute [rw] message_template_element
      #   @return [String, nil] The component that changed, e.g. `"BODY"`.
      attr_accessor :message_template_element

      def initialize(message_template_id:, message_template_name:, message_template_language:,
        message_template_element:)
        @message_template_id = message_template_id
        @message_template_name = message_template_name
        @message_template_language = message_template_language
        @message_template_element = message_template_element
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [MessageTemplateComponentsUpdate]
        def deserialize(data)
          data ||= {}

          new(
            message_template_id: data["message_template_id"],
            message_template_name: data["message_template_name"],
            message_template_language: data["message_template_language"],
            message_template_element: data["message_template_element"]
          )
        end
      end
    end
  end
end
