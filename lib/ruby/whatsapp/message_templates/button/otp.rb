# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class Button
      # The one-time-passcode button that authentication templates are built around.
      #
      # Unlike every other button, its label is not settable: Meta supplies and
      # localises both `text` and `autofill_text` per language. Passing either is
      # therefore an error rather than something silently dropped.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/authentication-templates/authentication-templates
      class Otp < Base
        module Defaults
          TYPE = "OTP"
        end

        # How the recipient hands the code back to the business.
        module OtpTypes
          # Copies the code to the clipboard.
          COPY_CODE = "COPY_CODE"
          # Autofills the code into the requesting app.
          ONE_TAP = "ONE_TAP"
          # Delivers the code to a broadcast receiver with no user action.
          ZERO_TAP = "ZERO_TAP"
          # Renders no button at all.
          NO_BUTTONS = "NO_BUTTONS"

          ALL = [COPY_CODE, ONE_TAP, ZERO_TAP, NO_BUTTONS].freeze

          # OTP types that hand the code to an app and so must declare which apps
          # are allowed to receive it.
          REQUIRING_SUPPORTED_APPS = [ONE_TAP, ZERO_TAP].freeze
        end

        # @!attribute [rw] otp_type
        #   @return [String]
        attr_accessor :otp_type

        # @!attribute [rw] supported_apps
        #   @return [Array<Otp::SupportedApp>]
        attr_accessor :supported_apps

        # @!attribute [rw] zero_tap_terms_accepted
        #   @return [Boolean, nil]
        attr_accessor :zero_tap_terms_accepted

        # @!attribute [rw] text
        #   Always nil — see the class comment.
        #   @return [nil]
        attr_accessor :text

        # @!attribute [rw] autofill_text
        #   Always nil — see the class comment.
        #   @return [nil]
        attr_accessor :autofill_text

        validates :otp_type, presence: true, inclusion: { in: OtpTypes::ALL }
        validate :validate_supported_apps
        validate :validate_zero_tap_terms
        validate :validate_no_labels

        # @param otp_type [String, Symbol] One of {OtpTypes::ALL}, any casing.
        # @param supported_apps [Array<Hash, Otp::SupportedApp>] Apps allowed to
        #   receive the code. Required for ONE_TAP and ZERO_TAP.
        # @param zero_tap_terms_accepted [Boolean, nil] Must be true for ZERO_TAP.
        # @param text [String, nil] Not supported — Meta localises the label.
        # @param autofill_text [String, nil] Not supported — Meta localises the label.
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(otp_type:, supported_apps: [], zero_tap_terms_accepted: nil, text: nil, autofill_text: nil)
          @otp_type = normalize_otp_type(otp_type)
          @supported_apps = build_supported_apps(supported_apps)
          @zero_tap_terms_accepted = zero_tap_terms_accepted
          @text = text
          @autofill_text = autofill_text

          validate!
        end

        # @return [Hash] The serialized button.
        def serialize
          {
            type: Defaults::TYPE,
            otp_type:,
            supported_apps: serialized_supported_apps,
            zero_tap_terms_accepted:,
          }.compact
        end

      private

        # Meta's docs are inconsistent about enum casing; accept either and emit
        # uppercase, which is what responses come back as.
        # @return [String, nil]
        def normalize_otp_type(value)
          return if value.nil?

          candidate = value.to_s.upcase
          OtpTypes::ALL.include?(candidate) ? candidate : value.to_s
        end

        # @return [Array<Otp::SupportedApp>]
        # @raise [ActiveModel::ValidationError] if a supported app is invalid.
        def build_supported_apps(apps)
          Array(apps).map { |app| app.is_a?(SupportedApp) ? app : SupportedApp.new(**app) }
        end

        # @return [Array<Hash>, nil] nil when empty, so `compact` drops the key.
        def serialized_supported_apps
          return if supported_apps.empty?

          supported_apps.map(&:serialize)
        end

        # @return [void]
        def validate_supported_apps
          return unless OtpTypes::REQUIRING_SUPPORTED_APPS.include?(otp_type)
          return unless supported_apps.empty?

          errors.add(:supported_apps, "can't be blank for the #{otp_type} OTP type")
        end

        # @return [void]
        def validate_zero_tap_terms
          return unless otp_type == OtpTypes::ZERO_TAP
          return if zero_tap_terms_accepted == true

          errors.add(:zero_tap_terms_accepted, "must be accepted for the ZERO_TAP OTP type")
        end

        # @return [void]
        def validate_no_labels
          reject_unsupported(:text, "cannot be set on an OTP button; Meta localises the label")
          reject_unsupported(:autofill_text, "cannot be set on an OTP button; Meta localises the label")
        end
      end
    end
  end
end
