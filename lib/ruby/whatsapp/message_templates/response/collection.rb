# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    module Response
      # A page of templates: `{data, paging, summary}`.
      #
      # Enumerable over its templates, so `list.select(&:approved?)` reads naturally
      # without reaching for `.data` first.
      #
      # Paging is exposed rather than followed automatically: the caller decides whether
      # to walk the whole account, and passing {#next_cursor} back as `after:` is one
      # line. Auto-pagination would hide an unbounded number of requests behind a single
      # innocuous-looking call.
      # Source: https://developers.facebook.com/docs/graph-api/reference/whats-app-business-account/message_templates/
      class Collection
        include Enumerable

        # @!attribute [rw] data
        #   @return [Array<Node>]
        attr_accessor :data

        # @!attribute [rw] paging
        #   @return [Paging, nil]
        attr_accessor :paging

        # @!attribute [rw] summary
        #   @return [Summary, nil]
        attr_accessor :summary

        # @param data [Array<Node>]
        # @param paging [Paging, nil]
        # @param summary [Summary, nil]
        def initialize(data: [], paging: nil, summary: nil)
          @data = data
          @paging = paging
          @summary = summary
        end

        class << self
          # @param response [Hash, nil] The parsed response body.
          # @return [Collection]
          def deserialize(response)
            response ||= {}

            new(
              data: Array(response["data"]).map { |node| Node.deserialize(node) },
              paging: response["paging"] && Paging.deserialize(response["paging"]),
              summary: response["summary"] && Summary.deserialize(response["summary"])
            )
          end
        end

        # @yieldparam template [Node]
        # @return [Enumerator]
        def each(&)
          data.each(&)
        end

        # The cursor to pass as `after:` to fetch the next page.
        # @return [String, nil]
        def next_cursor
          paging&.after
        end

        # How many more templates the account can hold.
        # @return [Integer, nil]
        def remaining
          summary&.remaining
        end
      end
    end
  end
end
