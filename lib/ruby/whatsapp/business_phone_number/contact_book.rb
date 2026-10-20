# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    # Removes a stored user contact from your **contact book** — the store Meta keeps of
    # the phone numbers and BSUIDs you have interacted with, and uses to keep putting a
    # user's phone number in your webhooks after they adopt a username.
    #
    # Addressed as a `phone_id` edge (`DELETE /{phone_id}/contact_book`), so it reuses
    # {BusinessPhoneNumber::Transport} unchanged, like {Profile} and {Username}. It sits
    # here rather than in a top-level module for two reasons: this directory is the
    # administration of one phone number, as opposed to {Whatsapp::Media} and
    # {Whatsapp::Messages}, which are the traffic itself; and a top-level module would
    # need its own error class for a single endpoint, where living here means one
    # `rescue BusinessPhoneNumber::Error` still covers the whole directory.
    #
    # Note the asymmetry between how it is addressed and what it affects: the edge is on
    # one phone number, but the contact book is scoped to the whole **business portfolio**,
    # so a deletion removes that user's phone number from webhooks for *every* number in
    # the portfolio. See `docs/business_phone_number/contact_book.md`.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
    module ContactBook
    end
  end
end
