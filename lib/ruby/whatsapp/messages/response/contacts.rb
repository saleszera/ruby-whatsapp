# frozen_string_literal: true

module Whatsapp
  class Messages
    class Response
      class Contacts
        # @!attribute [rw] input
        #   @return [String] Whatever you addressed the message to: the phone number, the
        #     BSUID or parent BSUID, or a group ID.
        attr_accessor :input

        # @!attribute [rw] wa_id
        #   @return [String, nil] The recipient's WhatsApp ID. Present only if the message
        #     was sent to their phone number; omitted otherwise.
        attr_accessor :wa_id

        # @!attribute [rw] user_id
        #   @return [String, nil] The recipient's business-scoped user ID (BSUID), or parent
        #     BSUID — Meta returns either in this one field, unlike the webhook classes,
        #     which separate `user_id` from `parent_user_id`.
        #
        #     Omitted whenever the message went to a phone number, **including when both
        #     `to` and `recipient` were supplied**, since Meta gives `to` precedence and
        #     answers as though `recipient` had not been sent. A `nil` here therefore does
        #     not mean the recipient has no BSUID.
        attr_accessor :user_id

        # @param input [String] The input value of the contact.
        # @param wa_id [String, nil] The WhatsApp ID of the contact, if it was addressed by
        #   phone number.
        # @param user_id [String, nil] The contact's BSUID, if it was addressed by one.
        def initialize(input:, wa_id: nil, user_id: nil)
          @input = input
          @wa_id = wa_id
          @user_id = user_id
        end

        class << self
          # Deserializes a hash into a Messages::Response::Contacts object.
          # @param data [Hash] The hash representation of the contact response.
          #   @return [Messages::Response::Contacts] The deserialized contact response object.
          def deserialize(data)
            new(
              input: data["input"],
              wa_id: data["wa_id"],
              user_id: data["user_id"]
            )
          end
        end
      end
    end
  end
end
