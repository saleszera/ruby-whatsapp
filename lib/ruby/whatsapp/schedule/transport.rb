# frozen_string_literal: true

module Whatsapp
  module Schedule
    # The one piece shared by {List} and {Create}: both address the same WABA-scoped
    # edge, differing only in HTTP verb and body. Extended (not included) because
    # {#edge_path} is used from class-level `.call` methods (as a private class method).
    #
    # The guard itself and its message live in {Whatsapp::PathBuilding}, shared with every
    # other ID-scoped feature; what stays here is the edge this module addresses.
    module Transport
      include Whatsapp::PathBuilding

    private

      # @param client [Whatsapp::Client]
      # @return [String] The versioned path to the `schedules` edge.
      # @raise [Error] if no WABA ID is configured.
      def edge_path(client)
        scoped_path(client, :waba_id, "schedules", error_class: Error, purpose: "schedules")
      end
    end
  end
end
