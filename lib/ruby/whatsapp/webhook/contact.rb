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

      # @!attribute [rw] username
      #   @return [String, nil] Set only if the user has adopted a username.
      attr_accessor :username

      # @!attribute [rw] wa_id
      #   @return [String, nil] Omitted once the user adopts a username, unless a
      #     recent interaction or the contact book still allows sharing the phone number.
      attr_accessor :wa_id

      # @!attribute [rw] user_id
      #   @return [String, nil] The user's business-scoped user ID (BSUID).
      attr_accessor :user_id

      # @!attribute [rw] parent_user_id
      #   @return [String, nil] The user's parent BSUID, present only when enrolled.
      attr_accessor :parent_user_id

      def initialize(profile_name:, username:, wa_id:, user_id:, parent_user_id:)
        @profile_name = profile_name
        @username = username
        @wa_id = wa_id
        @user_id = user_id
        @parent_user_id = parent_user_id
      end

      class << self
        # @param data [Hash] A raw `contacts[]` entry.
        # @return [Contact]
        def deserialize(data)
          data ||= {}

          new(
            profile_name: data.dig("profile", "name"),
            username: data.dig("profile", "username"),
            wa_id: data["wa_id"],
            user_id: data["user_id"],
            parent_user_id: data["parent_user_id"]
          )
        end
      end
    end
  end
end
