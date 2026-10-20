# frozen_string_literal: true

module Whatsapp
  class Messages
    class Base
      include ActiveModel::Validations

      module Messaging
        PRODUCT = "whatsapp"
        RECIPIENT_TYPE = "individual"
      end

      # The two ways to address a message. Drives both the "at least one" guard and its
      # message, so the rule and its wording cannot drift apart.
      RECIPIENT_ATTRIBUTES = %i[to recipient].freeze

      # @!attribute [rw] to
      #   @return [String, nil] The recipient's phone number. Optional since Meta added
      #     {#recipient}, but still the identifier that wins if both are given.
      attr_accessor :to

      # @!attribute [rw] recipient
      #   @return [String, nil] The recipient's business-scoped user ID (BSUID), e.g.
      #     `"US.13491208655302741918"`, or a parent BSUID, e.g.
      #     `"US.ENT.11815799212886844830"` — a country code, a period, and up to 128
      #     alphanumeric characters, with `ENT.` inserted for a parent BSUID. Pass the
      #     whole value; omitting or altering any part of it fails the request.
      #
      #     Deliberately not format-checked here. Meta describes the shape but publishes
      #     no client-side rule for it, and the canonical source of a BSUID is this gem's
      #     own webhook side ({Whatsapp::Webhook::Contact#user_id} and friends), which
      #     keeps it as a raw string — rejecting on the way out what was accepted on the
      #     way in would be the worst possible asymmetry.
      attr_accessor :recipient

      validate :validate_recipient_present
      validates :to, presence: true, allow_nil: true
      validates :recipient, presence: true, allow_nil: true

      # @param to [String, nil] The recipient's phone number.
      # @param recipient [String, nil] The recipient's BSUID or parent BSUID. Supply
      #   either or both of `to`/`recipient`; Meta gives `to` precedence when both are
      #   present.
      #  @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(to: nil, recipient: nil)
        @to = to
        @recipient = recipient
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
          **recipient_fields,
          type:,
          **body,
        }
      end

    private

      # Only the recipient pair is compacted, not the whole envelope: an absent
      # identifier must be left out rather than sent as null, but compacting the outer
      # hash would also swallow a `nil` a subclass passes in `body`.
      # @return [Hash] Whichever of `to`/`recipient` was given.
      def recipient_fields
        { to:, recipient: }.compact
      end

      # @return [void]
      def validate_recipient_present
        return if RECIPIENT_ATTRIBUTES.any? { |attribute| !public_send(attribute).nil? }

        errors.add(:base, "at least one of #{RECIPIENT_ATTRIBUTES.join(' or ')} must be provided")
      end
    end
  end
end
