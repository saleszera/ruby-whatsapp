# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    # The one piece shared by {Register}, {Deregister}, {RequestCode}, {VerifyCode}, and
    # {Profile}: all of them address a phone-number-scoped edge, differing only in edge name
    # and body. Extended (not included) because {#edge_path} is used from class-level `.call`
    # methods (as a private class method).
    #
    # The guard itself and its message live in {Whatsapp::PathBuilding}, shared with every
    # other ID-scoped feature; what stays here is the ID this module addresses.
    module Transport
      include Whatsapp::PathBuilding

    private

      # @param client [Whatsapp::Client]
      # @param action [String] The edge to address ("register", "deregister",
      #   "request_code", "verify_code", or "whatsapp_business_profile").
      # @return [String] The versioned path to the phone number's action edge.
      # @raise [Error] if no phone number ID is configured.
      def edge_path(client, action)
        scoped_path(client, :phone_id, action, error_class: Error, purpose: "the #{action} edge")
      end
    end
  end
end
