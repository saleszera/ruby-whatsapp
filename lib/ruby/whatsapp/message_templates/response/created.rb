# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    module Response
      # The response to creating a template: `{id, status, category}`.
      #
      # `status` is worth checking rather than assuming: a template built from scratch
      # normally comes back PENDING and takes up to 24 hours to review, but a library
      # clone or an authentication template is usually APPROVED immediately, and a
      # category Meta disagrees with comes back REJECTED right away.
      #
      # `category` is echoed back because Meta may have reassigned it — automatic
      # recategorisation has been the default since 2025-04-09.
      # Source: https://developers.facebook.com/docs/graph-api/reference/whats-app-business-account/message_templates/
      class Created
        # @!attribute [rw] id
        #   @return [String, nil]
        attr_accessor :id

        # @!attribute [rw] status
        #   @return [String, nil]
        attr_accessor :status

        # @!attribute [rw] category
        #   @return [String, nil] The category Meta actually assigned.
        attr_accessor :category

        # @param id [String, nil]
        # @param status [String, nil]
        # @param category [String, nil]
        def initialize(id: nil, status: nil, category: nil)
          @id = id
          @status = status
          @category = category
        end

        class << self
          # @param data [Hash, nil] The parsed response body.
          # @return [Created]
          def deserialize(data)
            data ||= {}

            new(id: data["id"], status: data["status"], category: data["category"])
          end
        end

        # @return [Boolean] Whether the template is already sendable.
        def approved?
          status == Statuses::APPROVED
        end

        # @return [Boolean] Whether the template is still in review.
        def pending?
          status == Statuses::PENDING
        end

        # @return [Boolean] Whether the template failed review.
        def rejected?
          status == Statuses::REJECTED
        end
      end
    end
  end
end
