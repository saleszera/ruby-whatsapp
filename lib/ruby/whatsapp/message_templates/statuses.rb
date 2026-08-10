# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    # The review and health states a template moves through.
    #
    # Only APPROVED templates can be sent. Status changes arrive asynchronously via the
    # `message_template_status_update` webhook, already modelled by
    # {Whatsapp::Webhook::MessageTemplateStatusUpdate} — polling {MessageTemplates#find}
    # is the fallback, not the intended path.
    # Source: https://developers.facebook.com/docs/graph-api/reference/whats-app-business-hsm/
    module Statuses
      # Passed review and sendable.
      APPROVED = "APPROVED"
      # In review; can take up to 24 hours.
      PENDING = "PENDING"
      # Failed review or violated policy. See `rejected_reason`.
      REJECTED = "REJECTED"
      # Suspended after recurring negative feedback or low read rates.
      PAUSED = "PAUSED"
      # Permanently disabled. Cannot be sent, and cannot be deleted.
      DISABLED = "DISABLED"
      # An appeal is in progress.
      IN_APPEAL = "IN_APPEAL"
      # Deleted, with a 30-day window for messages already in flight.
      PENDING_DELETION = "PENDING_DELETION"
      DELETED = "DELETED"
      # Over a limit.
      LIMIT_EXCEEDED = "LIMIT_EXCEEDED"
      # Inactive for 12 months or more.
      ARCHIVED = "ARCHIVED"

      ALL = [
        APPROVED, PENDING, REJECTED, PAUSED, DISABLED,
        IN_APPEAL, PENDING_DELETION, DELETED, LIMIT_EXCEEDED, ARCHIVED,
      ].freeze

      # The only statuses Meta allows a template to be edited in. Approved templates
      # additionally carry rate limits (10 edits per 30 days, and 1 per 24 hours) that
      # cannot be checked locally.
      EDITABLE = [APPROVED, REJECTED, PAUSED].freeze

      # Reasons Meta gives for a REJECTED status.
      module RejectedReasons
        NONE = "NONE"
        ABUSIVE_CONTENT = "ABUSIVE_CONTENT"
        INVALID_FORMAT = "INVALID_FORMAT"
        PROMOTIONAL = "PROMOTIONAL"
        TAG_CONTENT_MISMATCH = "TAG_CONTENT_MISMATCH"
        SCAM = "SCAM"

        ALL = [NONE, ABUSIVE_CONTENT, INVALID_FORMAT, PROMOTIONAL, TAG_CONTENT_MISMATCH, SCAM].freeze
      end

      # Quality buckets derived from recipient feedback and engagement.
      module QualityScores
        GREEN = "GREEN"
        YELLOW = "YELLOW"
        RED = "RED"
        UNKNOWN = "UNKNOWN"

        ALL = [GREEN, YELLOW, RED, UNKNOWN].freeze
      end
    end
  end
end
