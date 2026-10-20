# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # Present when an inbound message replies to a previous one (e.g. a reply
      # swipe, or a tap on an interactive button/list from an earlier message).
      class Context
        # @!attribute [rw] from
        #   @return [String, nil] The WhatsApp ID of the quoted message's sender, absent
        #     once they adopt a username and their phone number is no longer shareable.
        attr_accessor :from

        # @!attribute [rw] from_user_id
        #   @return [String, nil] The quoted sender's BSUID, the fallback identifier once
        #     {#from} is gone. **The key name is inferred** by symmetry with
        #     {Base#from_user_id} — Meta has not published a `context` example carrying
        #     it. Validate against a real payload before depending on it.
        attr_accessor :from_user_id

        # @!attribute [rw] from_parent_user_id
        #   @return [String, nil] The quoted sender's parent BSUID, present only for
        #     businesses enrolled in parent BSUIDs. Key name inferred, as above.
        attr_accessor :from_parent_user_id

        # @!attribute [rw] id
        #   @return [String, nil] The wamid of the message being replied to.
        attr_accessor :id

        # @!attribute [rw] forwarded
        #   @return [Boolean, nil]
        attr_accessor :forwarded

        # @!attribute [rw] frequently_forwarded
        #   @return [Boolean, nil]
        attr_accessor :frequently_forwarded

        def initialize(
          id:,
          from: nil, from_user_id: nil, from_parent_user_id: nil,
          forwarded: nil, frequently_forwarded: nil
        )
          @from = from
          @from_user_id = from_user_id
          @from_parent_user_id = from_parent_user_id
          @id = id
          @forwarded = forwarded
          @frequently_forwarded = frequently_forwarded
        end

        class << self
          # @param data [Hash, nil] The raw `context` hash.
          # @return [Context, nil]
          def deserialize(data)
            return if data.nil?

            new(
              from: data["from"],
              from_user_id: data["from_user_id"],
              from_parent_user_id: data["from_parent_user_id"],
              id: data["id"],
              forwarded: data["forwarded"],
              frequently_forwarded: data["frequently_forwarded"]
            )
          end
        end
      end
    end
  end
end
