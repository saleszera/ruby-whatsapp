# frozen_string_literal: true

module Whatsapp
  module Schedule
    # Lists a WABA's campaign schedules, one page at a time.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/schedules-api
    class List
      extend ResponseHandling
      extend Transport

      # The fields Meta documents for a schedule. Meta's default set is every one of
      # these except `id`, so ask for it explicitly when you need it. Offered for
      # convenience, not enforcement — {.call} does not validate `fields` against this
      # list, so a field Meta adds later works without a gem release.
      module Fields
        ID = "id"
        NAME = "name"
        DESCRIPTION = "description"
        DELIVERY_TIME = "delivery_time"
        STATUS = "status"

        ALL = [ID, NAME, DESCRIPTION, DELIVERY_TIME, STATUS].freeze
      end

      class << self
        # @example Read every field, including the id the default set leaves out
        #   List.call(fields: List::Fields::ALL)
        # @example Fetch the next page
        #   page = List.call(limit: 50)
        #   List.call(limit: 50, after: page.next_cursor) if page.next_cursor
        # @param client [Whatsapp::Client] The WhatsApp client instance.
        # @param fields [Array<String>, String, nil] Restrict each schedule to these
        #   fields; see {Fields::ALL}. Omitted when nil, so Meta returns its defaults.
        # @param limit [Integer, nil] Schedules per page; Meta accepts 1 to 100.
        # @param after [String, nil] Cursor for the page after this one.
        # @param before [String, nil] Cursor for the page before this one.
        # @return [Response::Collection]
        # @raise [Error] if no WABA ID is configured, or the request fails.
        def call(client: Client.new, fields: nil, limit: nil, after: nil, before: nil)
          params = { fields: fields && Array(fields).join(","), limit:, after:, before: }.compact
          response = client.connection.get(edge_path(client), params:)

          Response::Collection.deserialize(
            parse_json(handle_response!(response, error_class: Error, action: "list schedules"))
          )
        end
      end
    end
  end
end
