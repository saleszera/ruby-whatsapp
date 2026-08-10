# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    module Response
      # A full template as Meta returns it, from reading one template or from each
      # element of a list.
      #
      # `components` is deliberately left as raw hashes rather than rebuilt into the
      # {Component} classes. Those classes validate a payload being *written*, whereas
      # this is Meta's own echo of it: it carries fields the write side does not model,
      # and running write-side rules over data we did not author would raise on
      # perfectly valid responses. Read it as data; build a new {Template} when you want
      # to change something.
      # Source: https://developers.facebook.com/docs/graph-api/reference/whats-app-business-hsm/
      class Node
        # @!attribute [rw] id
        #   @return [String, nil]
        attr_accessor :id

        # @!attribute [rw] name
        #   @return [String, nil]
        attr_accessor :name

        # @!attribute [rw] status
        #   @return [String, nil] One of {Statuses::ALL}.
        attr_accessor :status

        # @!attribute [rw] category
        #   @return [String, nil]
        attr_accessor :category

        # @!attribute [rw] language
        #   @return [String, nil]
        attr_accessor :language

        # @!attribute [rw] components
        #   @return [Array<Hash>] Raw component hashes — see the class comment.
        attr_accessor :components

        # @!attribute [rw] parameter_format
        #   @return [String, nil]
        attr_accessor :parameter_format

        # @!attribute [rw] sub_category
        #   @return [String, nil]
        attr_accessor :sub_category

        # @!attribute [rw] rejected_reason
        #   @return [String, nil] One of {Statuses::RejectedReasons::ALL}.
        attr_accessor :rejected_reason

        # @!attribute [rw] quality_score
        #   @return [QualityScore, nil]
        attr_accessor :quality_score

        # @!attribute [rw] previous_category
        #   @return [String, nil] Set after an automatic recategorisation.
        attr_accessor :previous_category

        # @!attribute [rw] correct_category
        #   @return [String, nil] The category Meta believes this should be.
        attr_accessor :correct_category

        # @!attribute [rw] message_send_ttl_seconds
        #   @return [Integer, nil]
        attr_accessor :message_send_ttl_seconds

        # @!attribute [rw] cta_url_link_tracking_opted_out
        #   @return [Boolean, nil]
        attr_accessor :cta_url_link_tracking_opted_out

        # @!attribute [rw] library_template_name
        #   @return [String, nil] Set when the template was cloned from the library.
        attr_accessor :library_template_name

        # @param kwargs [Hash] One key per documented node field.
        def initialize(id: nil, name: nil, status: nil, category: nil, language: nil, components: [],
          parameter_format: nil, sub_category: nil, rejected_reason: nil, quality_score: nil,
          previous_category: nil, correct_category: nil, message_send_ttl_seconds: nil,
          cta_url_link_tracking_opted_out: nil, library_template_name: nil)
          @id = id
          @name = name
          @status = status
          @category = category
          @language = language
          @components = components
          @parameter_format = parameter_format
          @sub_category = sub_category
          @rejected_reason = rejected_reason
          @quality_score = quality_score
          @previous_category = previous_category
          @correct_category = correct_category
          @message_send_ttl_seconds = message_send_ttl_seconds
          @cta_url_link_tracking_opted_out = cta_url_link_tracking_opted_out
          @library_template_name = library_template_name
        end

        class << self
          # @param data [Hash, nil] The parsed response body, or one element of a list.
          # @return [Node]
          def deserialize(data)
            data ||= {}

            new(
              id: data["id"],
              name: data["name"],
              status: data["status"],
              category: data["category"],
              language: data["language"],
              components: Array(data["components"]),
              parameter_format: data["parameter_format"],
              sub_category: data["sub_category"],
              rejected_reason: data["rejected_reason"],
              quality_score: data["quality_score"] && QualityScore.deserialize(data["quality_score"]),
              previous_category: data["previous_category"],
              correct_category: data["correct_category"],
              message_send_ttl_seconds: data["message_send_ttl_seconds"],
              cta_url_link_tracking_opted_out: data["cta_url_link_tracking_opted_out"],
              library_template_name: data["library_template_name"]
            )
          end
        end

        # @return [Boolean] Whether the template can currently be sent.
        def approved?
          status == Statuses::APPROVED
        end

        # @return [Boolean]
        def rejected?
          status == Statuses::REJECTED
        end

        # @return [Boolean]
        def paused?
          status == Statuses::PAUSED
        end

        # Whether {MessageTemplates#update} would be accepted for this template.
        #
        # Status is the only part that can be checked locally. Approved templates are
        # also rate limited to 10 edits per 30 days and 1 per 24 hours, which only the
        # API can adjudicate.
        # @return [Boolean]
        def editable?
          Statuses::EDITABLE.include?(status)
        end
      end
    end
  end
end
