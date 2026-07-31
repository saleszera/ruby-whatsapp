# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      class Contacts < Base
        # The organization details of an inbound contact card.
        class Org
          # @!attribute [rw] company
          #   @return [String, nil]
          attr_accessor :company

          # @!attribute [rw] department
          #   @return [String, nil]
          attr_accessor :department

          # @!attribute [rw] title
          #   @return [String, nil]
          attr_accessor :title

          def initialize(company: nil, department: nil, title: nil)
            @company = company
            @department = department
            @title = title
          end

          class << self
            # @param data [Hash, nil] The raw `org` hash.
            # @return [Org]
            def deserialize(data)
              data ||= {}

              new(company: data["company"], department: data["department"], title: data["title"])
            end
          end
        end
      end
    end
  end
end
