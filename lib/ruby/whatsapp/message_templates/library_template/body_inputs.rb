# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class LibraryTemplate
      # The optional body content a library template exposes for customisation.
      #
      # Library templates have fixed wording, so these are toggles rather than text:
      # each one asks Meta to include a pre-written line or link in the body.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/template-library
      class BodyInputs
        include ValueObject

        module Defaults
          CODE_EXPIRATION_RANGE = (1..90)
        end

        # @!attribute [rw] add_contact_number
        #   @return [Boolean, nil]
        attr_accessor :add_contact_number

        # @!attribute [rw] add_learn_more_link
        #   @return [Boolean, nil]
        attr_accessor :add_learn_more_link

        # @!attribute [rw] add_security_recommendation
        #   @return [Boolean, nil]
        attr_accessor :add_security_recommendation

        # @!attribute [rw] add_track_package_link
        #   @return [Boolean, nil]
        attr_accessor :add_track_package_link

        # @!attribute [rw] code_expiration_minutes
        #   @return [Integer, nil]
        attr_accessor :code_expiration_minutes

        validate :validate_code_expiration

        # @param add_contact_number [Boolean, nil]
        # @param add_learn_more_link [Boolean, nil]
        # @param add_security_recommendation [Boolean, nil]
        # @param add_track_package_link [Boolean, nil]
        # @param code_expiration_minutes [Integer, nil] Must be within 1..90.
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(add_contact_number: nil, add_learn_more_link: nil, add_security_recommendation: nil,
          add_track_package_link: nil, code_expiration_minutes: nil)
          @add_contact_number = add_contact_number
          @add_learn_more_link = add_learn_more_link
          @add_security_recommendation = add_security_recommendation
          @add_track_package_link = add_track_package_link
          @code_expiration_minutes = code_expiration_minutes

          validate!
        end

        # @return [Hash] Only the toggles that were explicitly set.
        def serialize
          {
            add_contact_number:,
            add_learn_more_link:,
            add_security_recommendation:,
            add_track_package_link:,
            code_expiration_minutes:,
          }.compact
        end

      private

        # @return [void]
        def validate_code_expiration
          return if code_expiration_minutes.nil?
          return if code_expiration_minutes.is_a?(Integer) &&
            Defaults::CODE_EXPIRATION_RANGE.cover?(code_expiration_minutes)

          errors.add(:code_expiration_minutes, "must be in #{Defaults::CODE_EXPIRATION_RANGE}")
        end
      end
    end
  end
end
