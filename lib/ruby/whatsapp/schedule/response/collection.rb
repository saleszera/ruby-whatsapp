# frozen_string_literal: true

module Whatsapp
  module Schedule
    module Response
      # A page of campaign schedules: `{data, paging}`.
      #
      # Enumerable over its schedules, so `list.select(&:scheduled?)` reads naturally
      # without reaching for `.data` first.
      #
      # `paging` reuses {Whatsapp::MessageTemplates::Response::Paging}: the Graph API
      # cursor shape is identical, and only the cursors are kept, not the
      # `previous`/`next` URLs. As there, paging is exposed rather than followed
      # automatically; pass {#next_cursor} back as `after:` to fetch the next page.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/schedules-api
      class Collection
        include Enumerable

        # @!attribute [rw] data
        #   @return [Array<Node>]
        attr_accessor :data

        # @!attribute [rw] paging
        #   @return [Whatsapp::MessageTemplates::Response::Paging, nil]
        attr_accessor :paging

        # @param data [Array<Node>]
        # @param paging [Whatsapp::MessageTemplates::Response::Paging, nil]
        def initialize(data: [], paging: nil)
          @data = data
          @paging = paging
        end

        class << self
          # @param response [Hash, nil] The parsed response body.
          # @return [Collection]
          def deserialize(response)
            response ||= {}

            new(
              data: Array(response["data"]).map { |node| Node.deserialize(node) },
              paging: response["paging"] && MessageTemplates::Response::Paging.deserialize(response["paging"])
            )
          end
        end

        # @yieldparam schedule [Node]
        # @return [Enumerator]
        def each(&)
          data.each(&)
        end

        # The cursor to pass as `after:` to fetch the next page.
        # @return [String, nil]
        def next_cursor
          paging&.after
        end
      end
    end
  end
end
