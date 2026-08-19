# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module Account
      # The one piece shared by {Get} and {Update}: both address the WABA node itself,
      # differing only in HTTP verb and body. Extended (not included) since those
      # classes are class-method-only.
      #
      # Deliberately separate from {BusinessPhoneNumber::Transport}, which this shadows
      # by lexical scope inside {Account}. That one guards `phone_id` and always appends
      # an edge segment; this addresses `waba_id` and no edge at all. Both delegate the
      # guard and its wording to {Whatsapp::PathBuilding}, so the method names are now the
      # whole of the difference — `node_path` here, `edge_path` there, so the two can never
      # be confused at a call site.
      module Transport
        include Whatsapp::PathBuilding

      private

        # @param client [Whatsapp::Client]
        # @return [String] The versioned path to the WABA node, with no edge segment.
        # @raise [Error] if no WABA ID is configured.
        def node_path(client)
          scoped_path(client, :waba_id, error_class: Error, purpose: "business account details")
        end
      end
    end
  end
end
