# frozen_string_literal: true

module Whatsapp
  class Messages
    class Contacts
      # Represents a single contact entry within a contacts message.
      class Contact
        include ActiveModel::Validations

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

        validates :name, presence: true

        # @param name [Hash, Name] The contact's name. formatted_name is required.
        # @param phones [Array<Hash, Phone>] Phone numbers.
        # @param emails [Array<Hash, Email>] Email addresses.
        # @param addresses [Array<Hash, Address>] Physical addresses.
        # @param org [Hash, Org, nil] Organization details.
        # @param urls [Array<Hash, Url>] URLs.
        # @param birthday [String, nil] Birthday in YYYY-MM-DD format.
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(name:, phones: [], emails: [], addresses: [], org: nil, urls: [], birthday: nil)
          @name = name.is_a?(Name) ? name : Name.new(**name)
          @phones = phones.map { |p| p.is_a?(Phone) ? p : Phone.new(**p) }
          @emails = emails.map { |e| e.is_a?(Email) ? e : Email.new(**e) }
          @addresses = addresses.map { |a| a.is_a?(Address) ? a : Address.new(**a) }
          @org = if org
                   org.is_a?(Org) ? org : Org.new(**org)
                 end
          @urls = urls.map { |u| u.is_a?(Url) ? u : Url.new(**u) }
          @birthday = birthday

          validate!
        end

        # @return [Hash] The serialized contact payload.
        def serialize
          payload = { name: name.serialize }

          payload[:phones] = phones.map(&:serialize) if phones.any?
          payload[:emails] = emails.map(&:serialize) if emails.any?
          payload[:addresses] = addresses.map(&:serialize) if addresses.any?
          payload[:org] = org.serialize if org
          payload[:urls] = urls.map(&:serialize) if urls.any?
          payload[:birthday] = birthday if birthday

          payload
        end
      end
    end
  end
end
