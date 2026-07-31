# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      class Contacts < Base
        # The name component of an inbound contact card.
        class Name
          # @!attribute [rw] formatted_name
          #   @return [String, nil]
          attr_accessor :formatted_name

          # @!attribute [rw] first_name
          #   @return [String, nil]
          attr_accessor :first_name

          # @!attribute [rw] last_name
          #   @return [String, nil]
          attr_accessor :last_name

          # @!attribute [rw] middle_name
          #   @return [String, nil]
          attr_accessor :middle_name

          # @!attribute [rw] prefix
          #   @return [String, nil]
          attr_accessor :prefix

          # @!attribute [rw] suffix
          #   @return [String, nil]
          attr_accessor :suffix

          def initialize(formatted_name:, first_name: nil, last_name: nil, middle_name: nil, prefix: nil, suffix: nil)
            @formatted_name = formatted_name
            @first_name = first_name
            @last_name = last_name
            @middle_name = middle_name
            @prefix = prefix
            @suffix = suffix
          end

          class << self
            # @param data [Hash] The raw `name` hash.
            # @return [Name]
            def deserialize(data)
              data ||= {}

              new(
                formatted_name: data["formatted_name"],
                first_name: data["first_name"],
                last_name: data["last_name"],
                middle_name: data["middle_name"],
                prefix: data["prefix"],
                suffix: data["suffix"]
              )
            end
          end
        end
      end
    end
  end
end
