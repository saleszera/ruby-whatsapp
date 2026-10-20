# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # Common envelope shared by every inbound message type: who sent it, its
      # wamid, when it arrived, and (optionally) what it's replying to.
      class Base
        # @!attribute [rw] from
        #   @return [String, nil] Omitted once the sender adopts a username, unless a
        #     recent interaction or the contact book still allows sharing the phone number.
        attr_accessor :from

        # @!attribute [rw] from_user_id
        #   @return [String, nil] The sender's business-scoped user ID (BSUID).
        attr_accessor :from_user_id

        # @!attribute [rw] from_parent_user_id
        #   @return [String, nil] The sender's parent BSUID, present only when enrolled.
        attr_accessor :from_parent_user_id

        # @!attribute [rw] group_id
        #   @return [String, nil] Set only when the message was sent in a group chat.
        #     Reading groups works; this gem wraps no Groups API, so there is no way to
        #     reply into one — the id is for correlation and for filtering group traffic out.
        attr_accessor :group_id

        # @!attribute [rw] id
        #   @return [String, nil] The message's wamid.
        attr_accessor :id

        # @!attribute [rw] timestamp
        #   @return [String, nil]
        attr_accessor :timestamp

        # @!attribute [rw] type
        #   @return [String, nil]
        attr_accessor :type

        # @!attribute [rw] context
        #   @return [Context, nil]
        attr_accessor :context

        # @!attribute [rw] referral
        #   @return [Referral, nil]
        attr_accessor :referral

        def initialize(
          id:, timestamp:, type:,
          from: nil, from_user_id: nil, from_parent_user_id: nil, group_id: nil,
          context: nil, referral: nil
        )
          @from = from
          @from_user_id = from_user_id
          @from_parent_user_id = from_parent_user_id
          @group_id = group_id
          @id = id
          @timestamp = timestamp
          @type = type
          @context = context
          @referral = referral
        end

        class << self
          # Extracts the fields every message type shares, for subclasses to
          # merge with their own type-specific payload before calling `new`.
          # @param data [Hash] The raw message hash.
          # @return [Hash]
          def common_attributes(data)
            {
              from: data["from"],
              from_user_id: data["from_user_id"],
              from_parent_user_id: data["from_parent_user_id"],
              group_id: data["group_id"],
              id: data["id"],
              timestamp: data["timestamp"],
              type: data["type"],
              context: Context.deserialize(data["context"]),
              referral: Referral.deserialize(data["referral"]),
            }
          end
        end
      end
    end
  end
end
