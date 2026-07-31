# frozen_string_literal: true

module Whatsapp
  module Webhook
    # A value-level `contacts[]` entry — identifies the WhatsApp user tied to a
    # notification (distinct from `Message::Contacts`, the inbound "share a contact
    # card" message type, which has its own richer shape).
    class Contact
      # @!attribute [rw] profile_name
      #   @return [String, nil]
      attr_accessor :profile_name

      # @!attribute [rw] wa_id
      #   @return [String, nil]
      attr_accessor :wa_id

      def initialize(profile_name:, wa_id:)
        @profile_name = profile_name
        @wa_id = wa_id
      end

      class << self
        # @param data [Hash] A raw `contacts[]` entry.
        # @return [Contact]
        def deserialize(data)
          data ||= {}

          new(
            profile_name: data.dig("profile", "name"),
            wa_id: data["wa_id"]
          )
        end
      end
    end
  end
end
