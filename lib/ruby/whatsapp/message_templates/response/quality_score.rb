# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    module Response
      # A template's quality assessment, derived from usage, recipient feedback and
      # engagement. A falling score is what precedes a PAUSED and then DISABLED status.
      #
      # Best-effort schema: Meta names the shape (`WhatsAppBusinessHSMQualityScoreShape`)
      # in the Graph API reference but does not publish its sub-fields. The three mapped
      # here are what live responses have been observed to carry. Validate against a real
      # response before relying on them, as with the best-effort webhook classes in
      # `lib/ruby/whatsapp/webhook/CLAUDE.md`.
      # Source: https://developers.facebook.com/docs/graph-api/reference/whats-app-business-hsm/
      class QualityScore
        # @!attribute [rw] score
        #   @return [String, nil] One of {Statuses::QualityScores::ALL}.
        attr_accessor :score

        # @!attribute [rw] date
        #   @return [Integer, String, nil] When the score was last assessed.
        attr_accessor :date

        # @!attribute [rw] reasons
        #   @return [Array]
        attr_accessor :reasons

        # @param score [String, nil]
        # @param date [Integer, String, nil]
        # @param reasons [Array, nil]
        def initialize(score: nil, date: nil, reasons: [])
          @score = score
          @date = date
          @reasons = reasons
        end

        class << self
          # @param data [Hash, nil]
          # @return [QualityScore]
          def deserialize(data)
            data ||= {}

            new(score: data["score"], date: data["date"], reasons: Array(data["reasons"]))
          end
        end
      end
    end
  end
end
