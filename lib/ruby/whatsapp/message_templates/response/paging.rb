# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    module Response
      # Graph API cursor pagination for a template list.
      #
      # Flattens the nested `paging.cursors` object, since the intermediate level
      # carries no information of its own.
      # Source: https://developers.facebook.com/docs/graph-api/reference/whats-app-business-account/message_templates/
      class Paging
        # @!attribute [rw] before
        #   @return [String, nil] Cursor for the previous page.
        attr_accessor :before

        # @!attribute [rw] after
        #   @return [String, nil] Cursor for the next page.
        attr_accessor :after

        # @param before [String, nil]
        # @param after [String, nil]
        def initialize(before: nil, after: nil)
          @before = before
          @after = after
        end

        class << self
          # @param data [Hash, nil] The raw `paging` object.
          # @return [Paging]
          def deserialize(data)
            cursors = (data || {})["cursors"] || {}

            new(before: cursors["before"], after: cursors["after"])
          end
        end
      end
    end
  end
end
