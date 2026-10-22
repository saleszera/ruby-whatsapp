# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      # Interactive list messages allow you to present WhatsApp users with a list of options to choose from
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-list-messages
      class ListButtons < Base
        module Defaults
          MAX_BUTTON_LENGTH = 20
          MIN_SECTIONS_COUNT = 1
          MAX_SECTIONS_COUNT = 10
        end

        # @!attribute [rw] button
        #   @return [String]
        attr_accessor :button

        # @!attribute [rw] sections
        #   @return [Array<Hash>]
        attr_accessor :sections

        validates :button, presence: true, length: { maximum: Defaults::MAX_BUTTON_LENGTH }
        validates :sections, presence: true, length: { minimum: Defaults::MIN_SECTIONS_COUNT,
                                                       maximum: Defaults::MAX_SECTIONS_COUNT, }
        validate :validate_section_titles

        # @param button [String] The text for the list button.
        # @param sections [Array<Hash>] The sections of the list button.
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(button:, sections:)
          @button = button
          @sections = sections

          validate!
        end

        class << self
          # @return [Hash] Serialized representation of the ListButtons.
          #  @raise [ActiveModel::ValidationError] if validation fails.
          def serialize(**list_buttons)
            new(**list_buttons).serialize
          end
        end

        # @return [Hash] Serialized representation of the ListButtons.
        def serialize
          {
            button:,
            sections: serialized_sections,
          }
        end

      private

        # Meta requires `sections[].title` only once a list has more than one section, so
        # {Section} leaves it optional and the rule lives here, where the count is known.
        # A blank title counts as missing, matching {Section}, which omits it.
        # @return [void]
        def validate_section_titles
          return if sections.blank? || sections.size <= 1
          return if sections.all? { |section| section[:title].present? }

          errors.add(:sections, "must each have a title when there is more than one section")
        end

        # @return [Array<Hash>] Serialized sections.
        #   @raise [ActiveModel::ValidationError] if validation fails.
        def serialized_sections
          sections.map { |section| Section.serialize(**section) }
        end
      end
    end
  end
end
