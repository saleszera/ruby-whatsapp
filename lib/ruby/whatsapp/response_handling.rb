# frozen_string_literal: true

module Whatsapp
  # Shared handling of HTTP responses for API operations.
  module ResponseHandling
    # Maximum number of response-body characters to include in error messages,
    # to avoid leaking large or sensitive payloads into logs.
    MAX_ERROR_BODY = 500

  private

    # Returns the response when successful, otherwise raises error_class with a
    # message describing the failed action and a truncated body.
    # @param response [HTTP::Response]
    # @param error_class [Class] the exception class to raise on failure
    # @param action [String] a short description of the attempted action
    # @return [HTTP::Response] the successful response
    def handle_response!(response, error_class:, action:)
      return response if response.status.success?

      raise error_class, "Failed to #{action}: #{response.status} - #{truncate_body(response)}"
    end

    # @return [String] the response body truncated to MAX_ERROR_BODY characters
    def truncate_body(response)
      body = response.body.to_s
      return body if body.length <= MAX_ERROR_BODY

      "#{body[0, MAX_ERROR_BODY]}… (truncated)"
    end
  end
end
