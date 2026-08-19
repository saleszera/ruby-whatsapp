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
      # an edge segment; this addresses `waba_id` and no edge at all. The methods are
      # named differently — `node_path` here, `edge_path` there — so the two can never
      # be confused at a call site.
      module Transport
      private

        # @param client [Whatsapp::Client]
        # @return [String] The versioned path to the WABA node, with no edge segment.
        # @raise [Error] if no WABA ID is configured.
        def node_path(client)
          if client.waba_id.nil? || client.waba_id.to_s.empty?
            raise Error,
              "waba_id is required for business account details; " \
                "set it via Whatsapp.configure or Client.new(waba_id:)"
          end

          client.path_for(client.waba_id)
        end
      end
    end
  end
end
