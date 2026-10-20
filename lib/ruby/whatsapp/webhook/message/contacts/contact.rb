# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      class Contacts < Base
        # A single inbound contact card.
        class Contact
          # @!attribute [rw] name
          #   @return [Name]
          attr_accessor :name

          # @!attribute [rw] phones
          #   @return [Array<Phone>]
          attr_accessor :phones

          # @!attribute [rw] emails
          #   @return [Array<Email>]
          attr_accessor :emails

          # @!attribute [rw] addresses
          #   @return [Array<Address>]
          attr_accessor :addresses

          # @!attribute [rw] org
          #   @return [Org, nil]
          attr_accessor :org

          # @!attribute [rw] urls
          #   @return [Array<Url>]
          attr_accessor :urls

          # @!attribute [rw] birthday
          #   @return [String, nil] Date in YYYY-MM-DD format.
          attr_accessor :birthday

          # @!attribute [rw] vcard
          #   @return [String, nil] The card's raw vCard, set only when `origin` is `"other"`.
          attr_accessor :vcard

          # @!attribute [rw] origin
          #   @return [String, nil] `"contact_request"` (a `REQUEST_CONTACT_INFO` button tap)
          #     or `"other"` (shared directly from the chat).
          attr_accessor :origin

          def initialize(name:, phones:, emails:, addresses:, urls:, org: nil, birthday: nil, vcard: nil, origin: nil)
            @name = name
            @phones = phones
            @emails = emails
            @addresses = addresses
            @org = org
            @urls = urls
            @birthday = birthday
            @vcard = vcard
            @origin = origin
          end

          class << self
            # @param data [Hash] A raw `contacts[]` entry.
            # @return [Contact]
            def deserialize(data)
              data ||= {}

              new(
                name: Name.deserialize(data["name"]),
                phones: Array(data["phones"]).map { |phone_data| Phone.deserialize(phone_data) },
                emails: Array(data["emails"]).map { |email_data| Email.deserialize(email_data) },
                addresses: Array(data["addresses"]).map { |address_data| Address.deserialize(address_data) },
                org: data["org"] ? Org.deserialize(data["org"]) : nil,
                urls: Array(data["urls"]).map { |url_data| Url.deserialize(url_data) },
                birthday: data["birthday"],
                vcard: data["vcard"],
                origin: data["origin"]
              )
            end
          end
        end
      end
    end
  end
end
