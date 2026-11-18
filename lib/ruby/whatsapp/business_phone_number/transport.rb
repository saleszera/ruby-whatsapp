# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    # The one piece shared by {Register}, {Deregister}, {RequestCode}, {VerifyCode},
    # {Profile}, {Username}, {ContactBook}, and {ConversationalAutomation}: all of them
    # address the phone number, differing only in edge name and body. Extended (not
    # included) because {#edge_path} and {#node_path} are used from class-level `.call`
    # methods (as private class methods).
    #
    # Two methods rather than one with an optional segment, for the same reason
    # {Account::Transport} is separate: the name says at the call site whether an edge or
    # the node itself is addressed. {ConversationalAutomation::Get} is the one caller of
    # {#node_path} — Meta exposes that read as a *field* on the phone number node.
    #
    # The guard itself and its message live in {Whatsapp::PathBuilding}, shared with every
    # other ID-scoped feature; what stays here is the ID this module addresses.
    module Transport
      include Whatsapp::PathBuilding

    private

      # @param client [Whatsapp::Client]
      # @param action [String] The edge to address ("register", "deregister",
      #   "request_code", "verify_code", "whatsapp_business_profile", "username",
      #   "username_suggestions", "contact_book", or "conversational_automation").
      # @return [String] The versioned path to the phone number's action edge.
      # @raise [Error] if no phone number ID is configured.
      def edge_path(client, action)
        scoped_path(client, :phone_id, action, error_class: Error, purpose: "the #{action} edge")
      end

      # @param client [Whatsapp::Client]
      # @return [String] The versioned path to the phone number node, with no edge segment.
      # @raise [Error] if no phone number ID is configured.
      def node_path(client)
        scoped_path(client, :phone_id, error_class: Error, purpose: "the phone number node")
      end
    end
  end
end
