# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    # The one piece shared by {Register} and {Deregister}: both address the same
    # phone-number-scoped resource, differing only in edge name and body. Extended (not
    # included) since those classes are class-method-only.
    module Transport
    private

      # @param client [Whatsapp::Client]
      # @param action [String] The edge to address ("register" or "deregister").
      # @return [String] The versioned path to the phone number's action edge.
      # @raise [Error] if no phone number ID is configured.
      def edge_path(client, action)
        if client.phone_id.nil? || client.phone_id.to_s.empty?
          raise Error,
            "phone_id is required to #{action} a business phone number; " \
              "set it via Whatsapp.configure or Client.new(phone_id:)"
        end

        client.path_for(client.phone_id, action)
      end
    end
  end
end
