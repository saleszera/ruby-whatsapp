# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # An inbound shared contact card (or cards).
      class Contacts < Base
        # @!attribute [rw] contacts
        #   @return [Array<Contact>]
        attr_accessor :contacts

        def initialize(contacts:, **base_attributes)
          super(**base_attributes)

          @contacts = contacts
        end

        class << self
          # @param data [Hash] The raw message hash.
          # @return [Contacts]
          def deserialize(data)
            new(
              contacts: Array(data["contacts"]).map { |contact_data| Contact.deserialize(contact_data) },
              **common_attributes(data)
            )
          end
        end
      end
    end
  end
end
