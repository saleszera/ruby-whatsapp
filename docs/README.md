# ruby-whatsapp documentation

Full reference for [ruby-whatsapp](https://github.com/saleszera/ruby-whatsapp). The
[project README](../README.md) is the short version.

## Start here

| Page | Covers |
| --- | --- |
| [configuration.md](configuration.md) | Credentials, the client, connection reuse, instrumentation, which ID addresses what |
| [errors.md](errors.md) | The full exception hierarchy, validation vs API failures, retry strategy |

## Outbound — talking to customers

| Page | Covers |
| --- | --- |
| [messages/](messages/README.md) | Sending every message kind, the shared envelope, responses |
| [media/](media/README.md) | Upload, download, delete, and the token-safety allowlist |
| [message_templates/](message_templates/README.md) | Creating and managing the templates you send |

### Message kinds

[text](messages/text.md) ·
[image](messages/image.md) ·
[video](messages/video.md) ·
[audio](messages/audio.md) ·
[document](messages/document.md) ·
[sticker](messages/sticker.md) ·
[reaction](messages/reaction.md) ·
[location](messages/location.md) ·
[contacts](messages/contacts.md) ·
[address](messages/address.md) ·
[location request](messages/location_request.md) ·
[template](messages/template.md) ·
[interactive](messages/interactive.md) ·
[mark as read](messages/mark_message_as_read.md)

### Template kinds

[standard](message_templates/standard.md) ·
[authentication](message_templates/authentication.md) ·
[carousel](message_templates/carousel.md) ·
[limited-time offer](message_templates/limited_time_offer.md) ·
[library](message_templates/library.md) ·
[components reference](message_templates/components.md) ·
[responses](message_templates/responses.md)

## Inbound — hearing back

| Page | Covers |
| --- | --- |
| [webhooks/](webhooks/README.md) | Install, verification, signature, dispatch, all 19 notification fields |
| [webhooks/messages.md](webhooks/messages.md) | Inbound messages and delivery statuses — the one you'll actually use |

## Account administration

| Page | Covers |
| --- | --- |
| [subscribed_app/](subscribed_app/README.md) | Turning webhook delivery on and off for a WABA |
| [business_phone_number/](business_phone_number/README.md) | Onboarding a phone number: request code → verify → register |
| [business_phone_number/account.md](business_phone_number/account.md) | Reading and updating the business account itself |

## Reading order

New to the Cloud API? Follow the setup path in order:

1. [configuration.md](configuration.md) — get credentials in place
2. [business_phone_number/](business_phone_number/README.md) — register the number
3. [messages/text.md](messages/text.md) — send something
4. [subscribed_app/](subscribed_app/README.md) — turn on webhook delivery
5. [webhooks/](webhooks/README.md) — receive the reply
6. [message_templates/](message_templates/README.md) — message outside the 24-hour window
