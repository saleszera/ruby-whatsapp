# frozen_string_literal: true

module Whatsapp
  class Messages
    class Base
      include ActiveModel::Validations

      module Messaging
        PRODUCT = "whatsapp"
        RECIPIENT_TYPE = "individual"
      end

      # @!attribute [rw] to
      #   @return [String]
      attr_accessor :to

      validates :to, presence: true

      # @param to [String] The recipient's phone number.
      #  @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(to:)
        @to = to
      end

      def serialize
        raise NotImplementedError, "Subclasses must implement the serialize method"
      end

    protected

      # Builds the common message envelope shared by all message types.
      # @param type [String] the WhatsApp message type (e.g. "text")
      # @param body [Hash] the type-specific payload merged into the envelope
      # @return [Hash]
      def envelope(type:, **body)
        {
          messaging_product: Messaging::PRODUCT,
          recipient_type: Messaging::RECIPIENT_TYPE,
          to:,
          type:,
          **body,
        }
      end
    end
  end
end
