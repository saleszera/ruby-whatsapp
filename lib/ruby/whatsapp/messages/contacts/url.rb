# frozen_string_literal: true

module Whatsapp
  class Messages
    class Contacts
      # Represents a URL entry in a contact message.
      class Url
        include ActiveModel::Validations

        module Types
          WEBSITE = "WEBSITE"
          HOMEPAGE = "HOMEPAGE"
          WORK = "WORK"
          HOME = "HOME"
          OTHER = "OTHER"

          ALL = [WEBSITE, HOMEPAGE, WORK, HOME, OTHER].freeze
        end

        # @!attribute [rw] url
        #   @return [String]
        attr_accessor :url

        # @!attribute [rw] type
        #   @return [String, nil]
        attr_accessor :type

        validates :url, presence: true
        validates :type, inclusion: { in: Types::ALL }, allow_nil: true

        # @param url [String] The URL.
        # @param type [String, nil] URL type. One of WEBSITE, HOMEPAGE, WORK, HOME, OTHER.
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(url:, type: nil)
          @url = url
          @type = type

          validate!
        end

        # @return [Hash] The serialized url payload.
        def serialize
          {
            url:,
            type:,
          }.compact
        end
      end
    end
  end
end
