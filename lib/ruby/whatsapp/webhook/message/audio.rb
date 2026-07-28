# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # An inbound audio message (voice note or audio clip).
      class Audio < Media
        # @!attribute [rw] voice
        #   @return [Boolean, nil] Whether this was recorded as a voice note.
        attr_accessor :voice

        def initialize(voice: nil, **media_and_base_attributes)
          super(**media_and_base_attributes)

          @voice = voice
        end

        class << self
          # @param data [Hash] The raw message hash.
          # @return [Audio]
          def deserialize(data)
            new(voice: data.dig("audio", "voice"), **media_attributes(data, "audio"), **common_attributes(data))
          end
        end
      end
    end
  end
end
