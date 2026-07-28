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

    # @param host [String] The API origin
    # @param version [String] The API version
    # @param api_key [String] The API key for authentication
    # @param phone_id [String] The phone ID associated with the WhatsApp Business Account
    # @param waba_id [String] The WhatsApp Business Account ID
    # @param media_host_allowlist [Array<String>] Hosts allowed for media downloads
    def initialize(host: Defaults::HOST, version: Defaults::VERSION, api_key: nil, phone_id: nil,
      waba_id: nil, media_host_allowlist: Defaults::MEDIA_HOST_ALLOWLIST)
      @host = host
      @version = version
      @api_key = api_key
      @phone_id = phone_id
      @waba_id = waba_id
      @media_host_allowlist = media_host_allowlist
    end

    # Redacts the api_key so it never leaks into logs or console output.
    # @return [String]
    def inspect
      redacted = api_key.nil? ? "nil" : "[REDACTED]"
      "#<#{self.class.name} host=#{host.inspect} version=#{version.inspect} " \
        "api_key=#{redacted} phone_id=#{phone_id.inspect} waba_id=#{waba_id.inspect}>"
    end
  end
end
