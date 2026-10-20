# frozen_string_literal: true

module Whatsapp
  module Webhook
    class SmbAppStateSync
      # A synced address-book entry from the WhatsApp Business app.
      #
      # The gem's third `Contact`, and none of them are interchangeable:
      # {Whatsapp::Webhook::Contact} is a notification's sender identity (`profile.name`,
      # `wa_id`), {Whatsapp::Webhook::Message::Contacts::Contact} is a shared contact
      # *card* of vCard-shaped arrays, and this is a device address-book row
      # (`full_name`, `first_name`, `phone_number`). Forcing any two together would mean
      # dual-key reads on both sides for no gain.
      #
      # A sibling of {StateSync} rather than nested inside it, following
      # {UserIdUpdate::IdChange}.
      class Contact
        # @!attribute [rw] full_name
        #   @return [String, nil]
        attr_accessor :full_name

        # @!attribute [rw] first_name
        #   @return [String, nil]
        attr_accessor :first_name

        # @!attribute [rw] phone_number
        #   @return [String, nil] Omitted once the contact adopts a username and their
        #     number is no longer shareable. Fall back to {#user_id}.
        attr_accessor :phone_number

        # @!attribute [rw] user_id
        #   @return [String, nil] The contact's business-scoped user ID (BSUID).
        attr_accessor :user_id

        # @!attribute [rw] parent_user_id
        #   @return [String, nil] The contact's parent BSUID, present only when enrolled.
        attr_accessor :parent_user_id

        # @!attribute [rw] username
        #   @return [String, nil] Set only if the contact has adopted a username. Read
        #     flat, unlike {Whatsapp::Webhook::Contact#username}, which Meta nests under
        #     `profile` — do not copy that dual read here.
        attr_accessor :username

        def initialize(
          full_name: nil, first_name: nil, phone_number: nil,
          user_id: nil, parent_user_id: nil, username: nil
        )
          @full_name = full_name
          @first_name = first_name
          @phone_number = phone_number
          @user_id = user_id
          @parent_user_id = parent_user_id
          @username = username
        end

        class << self
          # @param data [Hash, nil] A raw `contact` hash.
          # @return [Contact]
          def deserialize(data)
            data ||= {}

            new(
              full_name: data["full_name"],
              first_name: data["first_name"],
              phone_number: data["phone_number"],
              user_id: data["user_id"],
              parent_user_id: data["parent_user_id"],
              username: data["username"]
            )
          end
        end
      end
    end
  end
end
