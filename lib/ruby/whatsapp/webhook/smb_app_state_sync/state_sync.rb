# frozen_string_literal: true

module Whatsapp
  module Webhook
    class SmbAppStateSync
      # A single contact-sync entry within an `smb_app_state_sync` notification.
      class StateSync
        # @!attribute [rw] type
        #   @return [String, nil]
        attr_accessor :type

        # @!attribute [rw] action
        #   @return [String, nil] e.g. `"add"`, `"remove"`, `"update"`.
        attr_accessor :action

        # @!attribute [rw] contact
        #   @return [Hash] Left untyped — Meta's docs don't publish this entry's schema.
        attr_accessor :contact

        def initialize(type:, action:, contact:)
          @type = type
          @action = action
          @contact = contact
        end

        class << self
          # @param data [Hash] A raw `state_sync[]` entry.
          # @return [StateSync]
          def deserialize(data)
            data ||= {}

            new(type: data["type"], action: data["action"], contact: data["contact"] || {})
          end
        end
      end
    end
  end
end
