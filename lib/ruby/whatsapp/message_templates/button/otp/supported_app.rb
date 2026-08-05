# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class Button
      class Otp
        # An Android app permitted to receive an autofilled one-time passcode.
        #
        # Required for the ONE_TAP and ZERO_TAP OTP types: Meta matches the delivering
        # app against these entries before handing over the code.
        # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/authentication-templates/authentication-templates
        class SupportedApp
          include ValueObject

          # @!attribute [rw] package_name
          #   @return [String]
          attr_accessor :package_name

          # @!attribute [rw] signature_hash
          #   @return [String]
          attr_accessor :signature_hash

          validates :package_name, presence: true
          validates :signature_hash, presence: true

          # @param package_name [String] The Android package name.
          # @param signature_hash [String] The app's signing signature hash.
          #  @raise [ActiveModel::ValidationError] if validation fails.
          def initialize(package_name:, signature_hash:)
            @package_name = package_name
            @signature_hash = signature_hash

            validate!
          end

          # @return [Hash] The serialized supported app.
          def serialize
            { package_name:, signature_hash: }
          end
        end
      end
    end
  end
end
