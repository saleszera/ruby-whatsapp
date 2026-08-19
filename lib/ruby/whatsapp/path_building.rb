# frozen_string_literal: true

module Whatsapp
  # The ID guard and path build shared by every WABA- or phone-number-scoped feature.
  #
  # Each feature keeps its own transport with a named method — {Whatsapp::SubscribedApp::Transport}'s
  # `edge_path`, {Whatsapp::BusinessPhoneNumber::Account::Transport}'s `node_path` — since those
  # names are what keep an edge and a node from being confused at a call site. This holds only
  # the part that was identical across all of them: refusing to address an unconfigured ID, and
  # phrasing that refusal the same way every time.
  module PathBuilding
  private

    # @param client [Whatsapp::Client]
    # @param id_name [Symbol] The client attribute to address (`:waba_id` or `:phone_id`).
    # @param segments [Array<String>] Edge segments after the ID; pass none to address the node itself.
    # @param error_class [Class] The feature's own error class, never {Whatsapp::RequestError}.
    # @param purpose [String] What the caller was reaching for, e.g. `"subscribed apps"`.
    # @return [String] The versioned path.
    # @raise [Whatsapp::Error] the given error_class, if the ID is not configured.
    def scoped_path(client, id_name, *segments, error_class:, purpose:)
      id = client.public_send(id_name)

      if id.nil? || id.to_s.empty?
        raise error_class,
          "#{id_name} is required for #{purpose}; " \
            "set it via Whatsapp.configure or Client.new(#{id_name}:)"
      end

      client.path_for(id, *segments)
    end
  end
end
