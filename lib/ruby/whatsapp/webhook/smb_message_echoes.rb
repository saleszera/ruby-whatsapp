# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Messages sent via the WhatsApp Business App or a linked device, echoed back so a
    # Cloud API integration stays in sync with what the business itself sent — including
    # messages the business revoked or edited from the app.
    #
    # Meta's BSUID documentation publishes the value-level `contacts` array and the
    # per-echo recipient identifiers. The array key itself (`message_echoes`) remains
    # inferred, hence {#raw}.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
    class SmbMessageEchoes
      # @!attribute [rw] messaging_product
      #   @return [String, nil]
      attr_accessor :messaging_product

      # @!attribute [rw] metadata
      #   @return [Metadata, nil]
      attr_accessor :metadata

      # @!attribute [rw] contacts
      #   @return [Array<Contact>] The customers these messages went to.
      attr_accessor :contacts

      # @!attribute [rw] message_echoes
      #   @return [Array<Echo>] Each pairs the echoed message with who it was sent to.
      attr_accessor :message_echoes

      # @!attribute [r] raw
      #   @return [Hash] The untouched `value` hash. A diagnostic escape hatch, not part of
      #     the supported API: {#message_echoes} reads `value["message_echoes"]`, a key
      #     inferred from the field's own name rather than confirmed by a published
      #     example, so a key that drifts would leave the array empty with no other trace.
      #     Read-only — it is the object `JSON.parse` returned, not a copy.
      attr_reader :raw

      def initialize(messaging_product:, metadata:, message_echoes:, contacts: [], raw: {})
        @messaging_product = messaging_product
        @metadata = metadata
        @contacts = contacts
        @message_echoes = message_echoes
        @raw = raw
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [SmbMessageEchoes]
        def deserialize(data)
          data ||= {}

          new(
            messaging_product: data["messaging_product"],
            metadata: data["metadata"] ? Metadata.deserialize(data["metadata"]) : nil,
            contacts: Array(data["contacts"]).map { |contact_data| Contact.deserialize(contact_data) },
            message_echoes: Array(data["message_echoes"]).map { |echo_data| Echo.deserialize(echo_data) },
            raw: data
          )
        end
      end
    end
  end
end
