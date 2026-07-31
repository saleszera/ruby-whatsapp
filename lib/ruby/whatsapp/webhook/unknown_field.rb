# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Fallback value wrapper for any webhook `field` not in {Change::FIELDS} — either
    # a field Meta added after this gem was released, or one deliberately left generic.
    # Keeps the raw hash accessible instead of raising on an unrecognized notification.
    class UnknownField
      # @!attribute [r] raw
      #   @return [Hash]
      attr_reader :raw

      def initialize(raw:)
        @raw = raw
      end

      # @param key [String]
      # @return [Object, nil]
      def [](key)
        raw[key]
      end

      # @return [Hash]
      def to_h
        raw
      end

      class << self
        # @param data [Hash, nil] The raw `value` hash.
        # @return [UnknownField]
        def deserialize(data)
          new(raw: data || {})
        end
      end
    end
  end
end
