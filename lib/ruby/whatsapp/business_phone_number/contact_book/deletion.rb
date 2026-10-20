# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module ContactBook
      # The result of a {Delete}: whether the request worked, and whether it found anything.
      #
      # Its own class rather than {BusinessPhoneNumber::Response}, which carries only
      # `success` (plus the `id` {VerifyCode} sets). `deleted` is a second, independent
      # boolean that changes how `success` reads — `success: true, deleted: false` means
      # the request was fine and there was simply no entry — and collapsing the two would
      # lose that. Adding it to the class every onboarding action returns would also put a
      # field on five actions that can never set it.
      class Deletion
        # @!attribute [rw] messaging_product
        #   @return [String, nil] Always `"whatsapp"`.
        attr_accessor :messaging_product

        # @!attribute [rw] success
        #   @return [Boolean] Whether the request was processed.
        attr_accessor :success

        # @!attribute [rw] deleted
        #   @return [Boolean] Whether an entry existed and was removed. `false` alongside a
        #     `true` {#success} means there was nothing stored for that BSUID — not a failure.
        attr_accessor :deleted

        def initialize(messaging_product: nil, success: false, deleted: false)
          @messaging_product = messaging_product
          @success = success
          @deleted = deleted
        end

        class << self
          # @param response [Hash, nil] The parsed response body.
          # @return [Deletion]
          def deserialize(response)
            response ||= {}

            new(
              messaging_product: response["messaging_product"],
              success: response["success"] == true,
              deleted: response["deleted"] == true
            )
          end
        end
      end
    end
  end
end
