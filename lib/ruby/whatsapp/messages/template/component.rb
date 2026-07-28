# frozen_string_literal: true

module Whatsapp
  class Messages
    class Template
      # Component for template messages (header, body, button)
      class Component
        include ActiveModel::Validations

        module Types
          HEADER = "header"
          BODY = "body"
          BUTTON = "button"
        end

        module SubTypes
          # Button sub_types
          QUICK_REPLY = "quick_reply"
          URL = "url"
          COPY_CODE = "copy_code"
        end

        # @!attribute [rw] type
        #   @return [String]
        attr_accessor :type

        # @!attribute [rw] sub_type
        #   @return [String, nil]
        attr_accessor :sub_type

        # @!attribute [rw] parameters
        #   @return [Array<Parameter>]
        attr_accessor :parameters

        # @!attribute [rw] index
        #   @return [Integer, nil]
        attr_accessor :index

        validates :type, presence: true, inclusion: { in: Types.constants.map { |c| Types.const_get(c) } }

        # @param type [String] The type of component (header, body, button).
        # @param sub_type [String, nil] The sub-type for button components (quick_reply, url).
        # @param parameters [Array<Hash, Parameter>] Array of parameter hashes.
        # @param index [Integer, nil] Button index for multiple buttons.
        def initialize(type:, sub_type: nil, parameters: [], index: nil)
          @type = type
          @sub_type = sub_type
          @parameters = parameters.map { |param| param.is_a?(Parameter) ? param : Parameter.new(**param) }
          @index = index

          validate!
        end

        # Serializes the component to a hash format suitable for the WhatsApp API.
        # @return [Hash] The serialized component.
        def serialize
          result = { type: }
          result[:sub_type] = sub_type if sub_type
          result[:index] = index if index
          result[:parameters] = parameters.map(&:serialize) if parameters.any?

          result.compact
        end
      end
    end
  end
end
