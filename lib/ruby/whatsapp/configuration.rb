# frozen_string_literal: true

module Whatsapp
  class Configuration
    module Defaults
      HOST = "https://graph.facebook.com"
      VERSION = "v24.0"
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
   
    # @param host [String] The API host URL
    # @param version [String] The API version
    # @param api_key [String] The API key for authentication
    # @param phone_id [String] The phone ID associated with the WhatsApp Business Account
    # @param waba_id [String] The WhatsApp Business Account ID
    def initialize(host: Defaults::HOST, version: Defaults::VERSION, api_key: nil, phone_id: nil, waba_id: nil)
      @host = host
      @version = version
      @api_key = api_key
      @phone_id = phone_id
      @waba_id = waba_id
    end
  end
end