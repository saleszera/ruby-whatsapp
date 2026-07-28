# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Status
      # The billing details attached to a status update.
      class Pricing
        # @!attribute [rw] billable
        #   @return [Boolean, nil]
        attr_accessor :billable

        # @!attribute [rw] pricing_model
        #   @return [String, nil]
        attr_accessor :pricing_model

        # @!attribute [rw] category
        #   @return [String, nil] e.g. `"service"`, `"marketing"`, `"utility"`, `"authentication"`.
        attr_accessor :category

        def initialize(billable:, pricing_model:, category:)
          @billable = billable
          @pricing_model = pricing_model
          @category = category
        end

        class << self
          # @param data [Hash] The raw `pricing` hash.
          # @return [Pricing]
          def deserialize(data)
            data ||= {}

            new(billable: data["billable"], pricing_model: data["pricing_model"], category: data["category"])
          end
        end
      end
    end
  end
end
