# frozen_string_literal: true

module Whatsapp
  # Media class for uploading, retrieving, downloading, and deleting media assets.
  # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/media
  class Media
    include ResponseHandling

    class MediaError < Whatsapp::Error; end

    # @!attribute [rw] client
    #   @return [Whatsapp::Client]
    attr_accessor :client

    # @param client [Whatsapp::Client] The WhatsApp client instance
    # @param media_host_allowlist [Array<String>] Hosts allowed to receive the
    #   bearer token during downloads (defaults to the global configuration).
    def initialize(client: Client.new, media_host_allowlist: Whatsapp.configuration.media_host_allowlist)
      @client = client
      @media_host_allowlist = media_host_allowlist
    end

    # Uploads a media file to WhatsApp.
    # @param file_path [String] Path to the file to upload
    # @param type [String] MIME type of the file (e.g., "image/jpeg", "video/mp4")
    # @return [String] The media ID
    # @raise [MediaError] if the file is missing or the upload fails
    def upload(file_path:, type:)
      raise MediaError, "File not found: #{file_path}" unless File.exist?(file_path)

      response = client.connection.post(
        client.path_for(client.phone_id, "media"),
        form: {
          messaging_product: "whatsapp",
          file: HTTP::FormData::File.new(file_path, content_type: type),
        }
      )

      parse_json(handle_response!(response, error_class: MediaError, action: "upload media"))["id"]
    end

    # Retrieves the URL for a media asset.
    # @param media_id [String] The media ID
    # @return [Hash] Hash containing url, mime_type, sha256, file_size, and id
    # @raise [MediaError] if the retrieval fails
    def get_url(media_id:)
      response = client.connection.get(
        client.path_for(media_id),
        params: { phone_number_id: client.phone_id }
      )

      parse_json(handle_response!(response, error_class: MediaError, action: "get media URL"))
    end

    # Downloads media from a media URL.
    #
    # The bearer token is attached to the request, so the URL is validated first:
    # it must be HTTPS and its host must be on the allowlist. This prevents the
    # token being sent to an attacker-influenced URL (media URLs commonly arrive
    # from inbound webhooks).
    # @param url [String] The media URL (valid for 5 minutes)
    # @param save_to [String] Path where to save the downloaded file
    # @return [String] Path to the saved file
    # @raise [MediaError] if the URL is untrusted or the download fails
    def download(url:, save_to:)
      uri = parse_download_url(url)

      response = HTTP.timeout(Client::DEFAULT_TIMEOUT)
        .auth("Bearer #{client.api_key}")
        .get(uri.to_s)

      handle_response!(response, error_class: MediaError, action: "download media")
      stream_to_file(response, save_to)

      save_to
    end

    # Deletes a media asset.
    # @param media_id [String] The media ID
    # @return [Boolean] true if successful
    # @raise [MediaError] if the deletion fails
    def delete(media_id:)
      response = client.connection.delete(
        client.path_for(media_id),
        params: { phone_number_id: client.phone_id }
      )

      parsed = parse_json(handle_response!(response, error_class: MediaError, action: "delete media"))
      parsed.is_a?(Hash) && parsed["success"] == true
    end

  private

    # Parses and validates a download URL (HTTPS + allowlisted host).
    # @return [URI::HTTPS]
    # @raise [MediaError] if the URL is invalid, not HTTPS, or not allowlisted
    def parse_download_url(url)
      uri =
        begin
          URI.parse(url)
        rescue URI::InvalidURIError => e
          raise MediaError, "Invalid media URL: #{e.message}"
        end

      raise MediaError, "Refusing to download from non-HTTPS URL: #{url}" unless uri.is_a?(URI::HTTPS)

      unless allowed_host?(uri.host)
        raise MediaError,
          "Refusing to send credentials to non-allowlisted host: #{uri.host}"
      end

      uri
    end

    # Bypass-safe host check: exact match or a dotted subdomain of an allowed host.
    # Rejects look-alikes such as "evil-fbsbx.com" or "fbsbx.com.attacker.com".
    # @return [Boolean]
    def allowed_host?(host)
      return false if host.nil? || host.empty?

      @media_host_allowlist.any? do |allowed|
        host == allowed || host.end_with?(".#{allowed}")
      end
    end

    # Streams the response body to disk in chunks rather than buffering it.
    # @return [void]
    def stream_to_file(response, save_to)
      File.open(save_to, "wb") do |file|
        response.body.each { |chunk| file.write(chunk) }
      end
    end
  end
end
