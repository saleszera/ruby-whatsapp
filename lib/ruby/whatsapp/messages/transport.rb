# frozen_string_literal: true

module Whatsapp
  class Messages
    # The one piece shared by {Messages#send!} and {Messages.mark_message_as_read!}:
    # both post to the same phone-number-scoped `messages` edge. Included and extended,
    # since one caller is an instance method and the other a class method.
    #
    # The guard itself and its message live in {Whatsapp::PathBuilding}, shared with every
    # other ID-scoped feature; what stays here is the edge this module addresses.
    module Transport
      include Whatsapp::PathBuilding

    private

      # @param client [Whatsapp::Client]
      # @return [String] The versioned path to the `messages` edge.
      # @raise [Whatsapp::RequestError] if no phone ID is configured.
      def messages_path(client)
        scoped_path(client, :phone_id, "messages", error_class: RequestError, purpose: "sending messages")
      end
    end
  end
end
