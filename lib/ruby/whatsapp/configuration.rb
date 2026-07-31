# frozen_string_literal: true

module Whatsapp
  class Configuration
    module Defaults
      HOST = "https://graph.facebook.com"
      VERSION = "v24.0"
      # Hosts allowed to receive the API bearer token during media downloads.
      # Meta serves media from these hosts; anything else is refused so the token
      # is never sent to an attacker-influenced URL.
      MEDIA_HOST_ALLOWLIST = %w[lookaside.fbsbx.com mmg.whatsapp.net graph.facebook.com].freeze
    end

    # @!attribute [rw] host
    # @return [String]
    attr_accessor :host

    # @!attribute [rw] version
    # @return [String]
    attr_accessor :version

    # @!attribute [rw] api_key
    # @return [String]
    attr_accessor :api_key

    # @!attribute [rw] phone_id
    # @return [String]
    attr_accessor :phone_id

    # @!attribute [rw] waba_id
    # @return [String]
    attr_accessor :waba_id

    # @!attribute [rw] media_host_allowlist
    # @return [Array<String>]
    attr_accessor :media_host_allowlist

    # @!attribute [rw] verify_token
    #   The token Meta must echo back during the webhook GET verification handshake.
    #   @return [String, nil]
    attr_accessor :verify_token

    # @!attribute [rw] app_secret
    #   Used to verify the `X-Hub-Signature-256` header on incoming webhook POSTs.
    #   @return [String, nil]
    attr_accessor :app_secret

    # @param host [String] The API origin
    # @param version [String] The API version
    # @param api_key [String] The API key for authentication
    # @param phone_id [String] The phone ID associated with the WhatsApp Business Account
    # @param waba_id [String] The WhatsApp Business Account ID
    # @param media_host_allowlist [Array<String>] Hosts allowed for media downloads
    # @param verify_token [String, nil] The default webhook verification token
    # @param app_secret [String, nil] The default webhook signing secret
    def initialize(host: Defaults::HOST, version: Defaults::VERSION, api_key: nil, phone_id: nil,
      waba_id: nil, media_host_allowlist: Defaults::MEDIA_HOST_ALLOWLIST, verify_token: nil, app_secret: nil)
      @host = host
      @version = version
      @api_key = api_key
      @phone_id = phone_id
      @waba_id = waba_id
      @media_host_allowlist = media_host_allowlist
      @verify_token = verify_token
      @app_secret = app_secret
    end

    # Redacts the api_key, app_secret, and verify_token so they never leak into logs or console output.
    # @return [String]
    def inspect
      redacted_api_key = api_key.nil? ? "nil" : "[REDACTED]"
      redacted_app_secret = app_secret.nil? ? "nil" : "[REDACTED]"
      redacted_verify_token = verify_token.nil? ? "nil" : "[REDACTED]"
      "#<#{self.class.name} host=#{host.inspect} version=#{version.inspect} " \
        "api_key=#{redacted_api_key} phone_id=#{phone_id.inspect} waba_id=#{waba_id.inspect} " \
        "verify_token=#{redacted_verify_token} app_secret=#{redacted_app_secret}>"
    end
  end
end
