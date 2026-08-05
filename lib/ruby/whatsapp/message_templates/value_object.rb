# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    # Shared behaviour for the nested value objects that make up a template payload:
    # components, buttons, carousel cards, and library inputs.
    #
    # Pulls together the three things every one of them needs — ActiveModel
    # validations, the class-level `.serialize` shorthand used throughout this gem,
    # and a couple of validation helpers — so they are declared once rather than
    # re-stated in each `Base`.
    module ValueObject
      # @param base [Class]
      # @return [void]
      def self.included(base)
        base.include(ActiveModel::Validations)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Builds an instance and serializes it in one step.
        # @return [Hash]
        def serialize(**)
          new(**).serialize
        end
      end

      # @return [Hash] The API payload for this object.
      def serialize
        raise NotImplementedError, "Subclasses must implement the serialize method"
      end

    protected

      # Plain-Ruby blank check, spelled out because the rest of this gem avoids
      # ActiveSupport's core extensions.
      #
      # Deliberately *not* named `blank?`: ActiveModel's presence validator calls
      # `value.blank?` on attribute values, so defining a one-argument `blank?` here
      # would shadow `Object#blank?` on every component and make
      # `validates :header, presence: true` raise instead of validate.
      # @param value [Object]
      # @return [Boolean]
      def blank_value?(value)
        value.nil? || (value.respond_to?(:empty?) && value.empty?)
      end

      # Records an error for a field Meta does not accept at template creation time.
      #
      # Used where Meta supplies the value itself (OTP and copy-code button labels) or
      # where the field is meaningless for the chosen shape (text on a location
      # header): silently dropping a caller's value would be worse than saying why it
      # is not allowed.
      # @param field [Symbol]
      # @param reason [String]
      # @return [void]
      def reject_unsupported(field, reason)
        errors.add(field, reason) unless blank_value?(public_send(field))
      end
    end
  end
end
