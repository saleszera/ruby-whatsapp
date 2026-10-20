# frozen_string_literal: true

module Whatsapp
  module Webhook
    class SmbAppStateSync
      # A single contact-sync entry within an `smb_app_state_sync` notification.
      class StateSync
        # @!attribute [rw] type
        #   @return [String, nil] `"contact"` is the only kind Meta documents.
        attr_accessor :type

        # @!attribute [rw] action
        #   @return [String, nil] e.g. `"add"`, `"remove"`, `"update"`.
        attr_accessor :action

        # @!attribute [rw] contact
        #   @return [Contact, nil] The synced address-book entry.
        attr_accessor :contact

        # @!attribute [rw] timestamp
        #   @return [String, nil] Flattened up from this entry's own `metadata.timestamp`.
        #     That nested object is *not* {Whatsapp::Webhook::Metadata} — it carries only a
        #     timestamp, so the wrapper is dropped rather than typed, the same habit as
        #     {Contact#profile_name}. Should Meta add a sibling key there, this becomes a
        #     class instead.
        attr_accessor :timestamp

        def initialize(type:, action:, contact: nil, timestamp: nil)
          @type = type
          @action = action
          @contact = contact
          @timestamp = timestamp
        end

        class << self
          # @param data [Hash] A raw `state_sync[]` entry.
          # @return [StateSync]
          def deserialize(data)
            data ||= {}

            new(
              type: data["type"],
              action: data["action"],
              contact: data["contact"] ? Contact.deserialize(data["contact"]) : nil,
              timestamp: data.dig("metadata", "timestamp")
            )
          end
        end
      end
    end
  end
end
