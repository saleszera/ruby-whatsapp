# frozen_string_literal: true

module Whatsapp
  module SubscribedApp
    # The one piece shared by {List}, {Subscribe}, and {Unsubscribe}: all three address
    # the same WABA-scoped edge, differing only in HTTP verb and body. Extended (not
    # included) since those classes are class-method-only.
    #
    # The guard itself and its message live in {Whatsapp::PathBuilding}, shared with every
    # other ID-scoped feature; what stays here is the edge this module addresses.
    module Transport
      include Whatsapp::PathBuilding

    private

      # @param client [Whatsapp::Client]
      # @return [String] The versioned path to the `subscribed_apps` edge.
      # @raise [Error] if no WABA ID is configured.
      def edge_path(client)
        scoped_path(client, :waba_id, "subscribed_apps", error_class: Error, purpose: "subscribed apps")
      end
    end
  end
end
