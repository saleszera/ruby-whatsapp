# frozen_string_literal: true

module Whatsapp
  module SubscribedApp
    # The one piece shared by {List}, {Subscribe}, and {Unsubscribe}: all three address
    # the same WABA-scoped edge, differing only in HTTP verb and body. Extended (not
    # included) since those classes are class-method-only.
    module Transport
    private

      # @param client [Whatsapp::Client]
      # @return [String] The versioned path to the `subscribed_apps` edge.
      # @raise [Error] if no WABA ID is configured.
      def edge_path(client)
        if client.waba_id.nil? || client.waba_id.to_s.empty?
          raise Error, "waba_id is required for subscribed apps; set it via Whatsapp.configure or Client.new(waba_id:)"
        end

        client.path_for(client.waba_id, "subscribed_apps")
      end
    end
  end
end
