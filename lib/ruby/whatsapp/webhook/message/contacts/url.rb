# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      class Contacts < Base
        # A URL entry within an inbound contact card.
        class Url
          # @!attribute [rw] url
          #   @return [String, nil]
          attr_accessor :url

          # @!attribute [rw] type
          #   @return [String, nil]
          attr_accessor :type

          def initialize(url:, type: nil)
            @url = url
            @type = type
          end

          class << self
            # @param data [Hash] A raw `urls[]` entry.
            # @return [Url]
            def deserialize(data)
              data ||= {}

              new(url: data["url"], type: data["type"])
            end
          end
        end
      end
    end
  end
end
