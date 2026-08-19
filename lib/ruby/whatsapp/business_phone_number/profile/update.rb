# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module Profile
      # Updates a business profile: its about text, description, contact details, websites,
      # industry vertical, and profile picture.
      #
      # A validated instance rather than a bare class method (unlike {Get}, which has nothing
      # to check): Meta documents a closed vertical enum and per-field character limits, and
      # since every field is optional an all-nil call would spend a request to change nothing.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/whatsapp-business-profile-api
      class Update
        include ActiveModel::Validations
        extend ResponseHandling
        extend Transport

        module Defaults
          MESSAGING_PRODUCT = "whatsapp"
          EDGE = "whatsapp_business_profile"
        end

        # The character and count limits Meta documents for a business profile.
        module Limits
          ABOUT = 139
          ADDRESS = 256
          DESCRIPTION = 512
          EMAIL = 128
          WEBSITES = 2
        end

        # Every updatable field, in payload order. Drives both the "change something"
        # guard and its message, so the two cannot drift apart.
        ATTRIBUTES = %i[about address description email vertical websites profile_picture_handle].freeze

        # @!attribute [rw] about
        #   @return [String, nil] The profile's about text, at most {Limits::ABOUT} characters.
        attr_accessor :about

        # @!attribute [rw] address
        #   @return [String, nil] The business's address, at most {Limits::ADDRESS} characters.
        attr_accessor :address

        # @!attribute [rw] description
        #   @return [String, nil] The business description, at most {Limits::DESCRIPTION} characters.
        attr_accessor :description

        # @!attribute [rw] email
        #   @return [String, nil] The contact email, at most {Limits::EMAIL} characters.
        attr_accessor :email

        # @!attribute [rw] vertical
        #   @return [String, nil] One of {Verticals::ALL}.
        attr_accessor :vertical

        # @!attribute [rw] websites
        #   @return [Array<String>, nil] At most {Limits::WEBSITES} URLs.
        attr_accessor :websites

        # @!attribute [rw] profile_picture_handle
        #   @return [String, nil] A picture handle from Meta's Resumable Upload API.
        attr_accessor :profile_picture_handle

        validate :validate_any_attribute_present
        validate :validate_websites_limit
        validates :about, length: { maximum: Limits::ABOUT }, allow_nil: true
        validates :address, length: { maximum: Limits::ADDRESS }, allow_nil: true
        validates :description, length: { maximum: Limits::DESCRIPTION }, allow_nil: true
        validates :email, length: { maximum: Limits::EMAIL }, allow_nil: true
        validates :vertical, inclusion: { in: Verticals::ALL }, allow_nil: true
        validates :profile_picture_handle, presence: true, allow_nil: true

        # @param about [String, nil] See {#about}.
        # @param address [String, nil] See {#address}.
        # @param description [String, nil] See {#description}.
        # @param email [String, nil] Length only — Meta validates the address itself
        #   server-side, and a format check here would reject valid exotic addresses.
        # @param vertical [String, Symbol, nil] One of {Verticals::ALL}, either casing.
        # @param websites [Array<String>, nil] At most {Limits::WEBSITES} URLs. An empty
        #   array is a deliberate instruction to clear the list, not an omission.
        # @param profile_picture_handle [String, nil] Opaque to this gem; presence only.
        # @raise [ActiveModel::ValidationError] if every field is nil, or one breaks a
        #   documented limit.
        def initialize(about: nil, address: nil, description: nil, email: nil, vertical: nil,
          websites: nil, profile_picture_handle: nil)
          @about = about
          @address = address
          @description = description
          @email = email
          @vertical = Verticals.normalize(vertical)
          @websites = websites
          @profile_picture_handle = profile_picture_handle

          validate!
        end

        # @return [Hash] The update payload. `messaging_product` is documented required so it
        #   is always sent; every other field is optional and an omitted one is compacted away
        #   rather than sent as null, which Meta would read as an instruction to blank it.
        #   An empty `websites` array survives compaction on purpose — that *is* the clear.
        def serialize
          { messaging_product: Defaults::MESSAGING_PRODUCT, about:, address:, description:,
            email:, vertical:, websites:, profile_picture_handle:, }.compact
        end

        class << self
          # @param client [Whatsapp::Client] The WhatsApp client instance.
          # @param about [String, nil] See {#initialize}.
          # @param address [String, nil] See {#initialize}.
          # @param description [String, nil] See {#initialize}.
          # @param email [String, nil] See {#initialize}.
          # @param vertical [String, Symbol, nil] See {#initialize}.
          # @param websites [Array<String>, nil] See {#initialize}.
          # @param profile_picture_handle [String, nil] See {#initialize}.
          # @return [BusinessPhoneNumber::Response]
          # @raise [ActiveModel::ValidationError] if no field is given, or one is invalid.
          # @raise [Error] if no phone number ID is configured, or the request fails.
          def call(client: Client.new, about: nil, address: nil, description: nil, email: nil,
            vertical: nil, websites: nil, profile_picture_handle: nil)
            body = new(about:, address:, description:, email:, vertical:, websites:,
              profile_picture_handle:).serialize
            response = client.connection.post(edge_path(client, Defaults::EDGE), json: body)

            BusinessPhoneNumber::Response.deserialize(
              parse_json(handle_response!(response, error_class: Error, action: "update business profile"))
            )
          end
        end

      private

        # @return [void]
        def validate_any_attribute_present
          return if ATTRIBUTES.any? { |attribute| !public_send(attribute).nil? }

          errors.add(:base, "at least one of #{ATTRIBUTES.join(', ')} must be provided")
        end

        # @return [void]
        def validate_websites_limit
          return if websites.nil? || websites.size <= Limits::WEBSITES

          errors.add(:base, "websites accepts at most #{Limits::WEBSITES} URLs")
        end
      end
    end
  end
end
