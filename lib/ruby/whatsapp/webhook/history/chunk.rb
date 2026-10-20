# frozen_string_literal: true

module Whatsapp
  module Webhook
    class History
      # A single `history[]` entry: one chunk of a chat-history sync, plus the counters
      # that tell you how far through the sync it is.
      class Chunk
        # @!attribute [rw] phase
        #   @return [Integer, nil] Which sync phase this chunk belongs to.
        attr_accessor :phase

        # @!attribute [rw] chunk_order
        #   @return [Integer, nil] This chunk's position within its phase.
        attr_accessor :chunk_order

        # @!attribute [rw] progress
        #   @return [Integer, nil] Percent complete, 0-100.
        attr_accessor :progress

        # @!attribute [rw] threads
        #   @return [Array<Thread>]
        attr_accessor :threads

        def initialize(phase: nil, chunk_order: nil, progress: nil, threads: [])
          @phase = phase
          @chunk_order = chunk_order
          @progress = progress
          @threads = threads
        end

        class << self
          # @param data [Hash, nil] A raw `history[]` entry.
          # @return [Chunk]
          def deserialize(data)
            data ||= {}
            metadata = data["metadata"] || {}

            new(
              phase: metadata["phase"],
              chunk_order: metadata["chunk_order"],
              progress: metadata["progress"],
              threads: Array(data["threads"]).map { |thread_data| Thread.deserialize(thread_data) }
            )
          end
        end
      end
    end
  end
end
