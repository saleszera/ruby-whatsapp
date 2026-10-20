# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module Username
      # The usernames Meta has reserved for your business portfolio, returned by {Suggest}.
      #
      # Owns the doubly-wrapped `{"data": [{"username_suggestions": [...]}]}` envelope so
      # callers never reach through it — the same flatten-the-meaningless-wrapper habit as
      # {Profile::Details}, {SubscribedApp::Response::App}, and
      # {MessageTemplates::Response::Paging}. Unlike {Profile::Details}, which reads only
      # `data[0]` because a phone number has exactly one profile, this flattens across
      # *every* entry: Meta's example shows one, but nothing documents that as a limit, and
      # `flat_map` is identical for one entry while degrading correctly for more.
      class Suggestions
        include Enumerable

        # @!attribute [rw] suggestions
        #   @return [Array<String>] Reserved usernames, which have a higher chance of
        #     approval than one you invent. Empty when Meta has reserved none.
        attr_accessor :suggestions

        def initialize(suggestions: [])
          @suggestions = suggestions
        end

        # @yieldparam suggestion [String]
        # @return [Enumerator, self]
        def each(&)
          return suggestions.each unless block_given?

          suggestions.each(&)
          self
        end

        class << self
          # @param response [Hash, nil] The parsed response body.
          # @return [Suggestions]
          def deserialize(response)
            response ||= {}

            new(
              suggestions: Array(response["data"]).flat_map { |entry| Array((entry || {})["username_suggestions"]) }
            )
          end
        end
      end
    end
  end
end
