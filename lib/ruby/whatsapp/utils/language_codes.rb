# frozen_string_literal: true

module Whatsapp
  module Utils
    # Utility module for WhatsApp supported language codes
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/supported-languages
    module LanguageCodes
      CODES = %w[
        af
        sq
        ar
        az
        bn
        bg
        ca
        zh_CN
        zh_HK
        zh_TW
        hr
        cs
        da
        nl
        en
        en_GB
        en_US
        et
        fil
        fi
        fr
        ka
        de
        el
        gu
        ha
        he
        hi
        hu
        id
        ga
        it
        ja
        kn
        kk
        rw_RW
        ko
        ky_KG
        lo
        lv
        lt
        mk
        ms
        ml
        mr
        nb
        fa
        pl
        pt_BR
        pt_PT
        pa
        ro
        ru
        sr
        sk
        sl
        es
        es_AR
        es_ES
        es_MX
        sw
        sv
        ta
        te
        th
        tr
        uk
        ur
        uz
        vi
        zu
      ].freeze

      # Check if a language code is valid
      # @param code [String] The language code to validate
      # @return [Boolean] true if the code is valid
      def self.valid?(code)
        CODES.include?(code.to_s)
      end

      # Get all supported language codes
      # @return [Array<String>] Array of all supported language codes
      def self.all
        CODES
      end
    end
  end
end
