# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class LibraryTemplate
      # One button's customisable values when cloning a library template.
      #
      # Deliberately *not* the same as {Button}: a library template already declares
      # which buttons it has and what they say, so these inputs only fill in the parts
      # Meta cannot know — a destination URL, a phone number, an app signature. There is
      # no `text`, and the shapes differ from the create-a-button-from-scratch ones (a
      # URL arrives as a `{base_url:, url_suffix_example:}` pair rather than a single
      # string with a placeholder).
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/template-library
      class ButtonInputs
        include ValueObject

        # The button kinds a library template may expose for customisation. Wider than
        # {Button::TYPES} because Meta documents these by name here even where it
        # publishes no create-from-scratch schema for them.
        module Types
          QUICK_REPLY = "QUICK_REPLY"
          URL = "URL"
          PHONE_NUMBER = "PHONE_NUMBER"
          OTP = "OTP"
          MPM = "MPM"
          CATALOG = "CATALOG"
          FLOW = "FLOW"
          VOICE_CALL = "VOICE_CALL"
          APP = "APP"

          ALL = [QUICK_REPLY, URL, PHONE_NUMBER, OTP, MPM, CATALOG, FLOW, VOICE_CALL, APP].freeze
        end

        # @!attribute [rw] type
        #   @return [String] one of {Types::ALL}.
        attr_accessor :type

        # @!attribute [rw] url
        #   @return [Hash, nil] `{ base_url:, url_suffix_example: }`.
        attr_accessor :url

        # @!attribute [rw] phone_number
        #   @return [String, nil]
        attr_accessor :phone_number

        # @!attribute [rw] otp_type
        #   @return [String, nil]
        attr_accessor :otp_type

        # @!attribute [rw] zero_tap_terms_accepted
        #   @return [Boolean, nil]
        attr_accessor :zero_tap_terms_accepted

        # @!attribute [rw] supported_apps
        #   @return [Array<Button::Otp::SupportedApp>, nil]
        attr_accessor :supported_apps

        validates :type, presence: true, inclusion: { in: Types::ALL }
        validate :validate_url
        validate :validate_phone_number
        validate :validate_supported_apps

        # @param type [String, Symbol] One of {Types::ALL}, any casing.
        # @param url [Hash, nil] Required for URL: `{ base_url:, url_suffix_example: }`.
        # @param phone_number [String, nil] Required for PHONE_NUMBER.
        # @param otp_type [String, Symbol, nil] For OTP inputs.
        # @param zero_tap_terms_accepted [Boolean, nil] For zero-tap OTP inputs.
        # @param supported_apps [Array<Hash, Button::Otp::SupportedApp>, nil] Required
        #   for APP.
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(type:, url: nil, phone_number: nil, otp_type: nil,
          zero_tap_terms_accepted: nil, supported_apps: nil)
          @type = normalize_type(type)
          @url = url&.then { |value| symbolize(value) }
          @phone_number = phone_number
          @otp_type = otp_type&.to_s&.upcase
          @zero_tap_terms_accepted = zero_tap_terms_accepted
          @supported_apps = build_supported_apps(supported_apps)

          validate!
        end

        # @return [Hash] The serialized button input.
        def serialize
          {
            type:,
            url:,
            phone_number:,
            otp_type:,
            zero_tap_terms_accepted:,
            supported_apps: supported_apps&.map(&:serialize),
          }.compact
        end

      private

        # @return [String, nil]
        def normalize_type(value)
          return if value.nil?

          candidate = value.to_s.upcase
          Types::ALL.include?(candidate) ? candidate : value.to_s
        end

        # @return [Hash]
        def symbolize(hash)
          hash.transform_keys(&:to_sym)
        end

        # @return [Array<Button::Otp::SupportedApp>, nil]
        def build_supported_apps(apps)
          return if apps.nil?

          Array(apps).map do |app|
            app.is_a?(Button::Otp::SupportedApp) ? app : Button::Otp::SupportedApp.new(**app)
          end
        end

        # @return [void]
        def validate_url
          return unless type == Types::URL
          return unless blank_value?(url) || blank_value?(url[:base_url])

          errors.add(:url, "requires a base_url for a #{Types::URL} button input")
        end

        # @return [void]
        def validate_phone_number
          return unless type == Types::PHONE_NUMBER
          return unless blank_value?(phone_number)

          errors.add(:phone_number, "can't be blank for a #{Types::PHONE_NUMBER} button input")
        end

        # @return [void]
        def validate_supported_apps
          return unless type == Types::APP
          return unless blank_value?(supported_apps)

          errors.add(:supported_apps, "can't be blank for an #{Types::APP} button input")
        end
      end
    end
  end
end
