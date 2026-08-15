# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    # The one piece shared by {Register}, {Deregister}, {RequestCode}, and
    # {VerifyCode}: all four address the same phone-number-scoped resource, differing
    # only in edge name and body. Extended (not included) since those classes are
    # class-method-only.
    module Transport
    private

      # @param client [Whatsapp::Client]
      # @param action [String] The edge to address ("register", "deregister",
      #   "request_code", or "verify_code").
      # @return [String] The versioned path to the phone number's action edge.
      # @raise [Error] if no phone number ID is configured.
      def edge_path(client, action)
        if client.phone_id.nil? || client.phone_id.to_s.empty?
          raise Error,
            "phone_id is required for the #{action} edge; " \
              "set it via Whatsapp.configure or Client.new(phone_id:)"
        end

        client.path_for(client.phone_id, action)
      end
    end
  end
end
