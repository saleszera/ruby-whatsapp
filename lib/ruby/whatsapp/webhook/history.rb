# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Chat history synchronization for onboarded business customers.
    #
    # Best-effort schema: Meta's public docs describe this field in one line with
    # no published JSON example; `threads`' entry shape isn't confidently
    # typeable from that description alone, so it's kept as a raw array rather
    # than guessing further. Validate against a real payload before relying on
    # this in production.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class History
      # @!attribute [rw] phase
      #   @return [Integer, nil]
      attr_accessor :phase

      # @!attribute [rw] chunk_order
      #   @return [Integer, nil]
      attr_accessor :chunk_order

      # @!attribute [rw] progress
      #   @return [Integer, nil]
      attr_accessor :progress

      # @!attribute [rw] threads
      #   @return [Array<Hash>]
      attr_accessor :threads

      def initialize(phase:, chunk_order:, progress:, threads:)
        @phase = phase
        @chunk_order = chunk_order
        @progress = progress
        @threads = threads
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [History]
        def deserialize(data)
          data ||= {}
          metadata = data["metadata"] || {}

          new(
            phase: metadata["phase"],
            chunk_order: metadata["chunk_order"],
            progress: metadata["progress"],
            threads: Array(data["threads"])
          )
        end
      end
    end
  end
end
