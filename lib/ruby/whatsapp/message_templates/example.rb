# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    # Builds the `example` payload Meta requires alongside any component text that
    # contains placeholders.
    #
    # This exists because the *key name* of that payload changes with both the
    # component and the template's parameter format — four combinations that are easy
    # to get wrong and are a common source of template rejections:
    #
    #            | POSITIONAL                    | NAMED
    #   ---------+-------------------------------+--------------------------------
    #   header   | header_text: ["Sale"]         | header_text_named_params: [...]
    #   body     | body_text: [["a", "b"]]       | body_text_named_params: [...]
    #
    # Note the asymmetry: `header_text` is a flat array while `body_text` is an array
    # *of arrays*. Meta documents no reason for it; it just is.
    #
    # Callers may pass a plain Array (positional), a Hash of name => example (named),
    # Meta's own `[{param_name:, example:}]` array, or a fully-built payload hash
    # copied verbatim out of Meta's docs — all four are accepted so pasting a known-
    # good example from the API reference works without translation.
    # Source: https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/components/
    module Example
      # Maps a component role to its example key for each parameter format.
      ROLES = {
        header: { positional: :header_text, named: :header_text_named_params },
        body: { positional: :body_text, named: :body_text_named_params },
      }.freeze

      # Keys that mean "the caller already built this payload, pass it through".
      # `header_handle` is included because media headers carry an asset handle here
      # rather than text parameters.
      BUILT_KEYS = (ROLES.values.flat_map(&:values) + [:header_handle]).freeze

      # Roles whose positional example is nested one level deeper.
      NESTED_ROLES = [:body].freeze

      class << self
        # @param role [Symbol] `:header` or `:body`.
        # @param parameter_format [String, Symbol, nil] see {ParameterFormats}.
        # @param values [Array, Hash, String, nil] the example value(s).
        # @return [Hash, nil] The example payload, or nil when there are no values.
        # @raise [ArgumentError] if the role is unknown or the values do not match the
        #   parameter format.
        def serialize(role:, parameter_format:, values:)
          keys = keys_for(role)
          return if blank_value?(values)
          return symbolize(values) if built?(values)

          if ParameterFormats.named?(parameter_format)
            { keys[:named] => named_params(values) }
          else
            { keys[:positional] => positional_values(role, values) }
          end
        end

        # The number of example values supplied, whatever shape they arrived in.
        #
        # Used by components to check the example count against the placeholder count
        # without needing to know which of the four shapes the caller used.
        # @return [Integer]
        def count(role:, parameter_format:, values:)
          payload = serialize(role:, parameter_format:, values:)
          return 0 if payload.nil?

          key, value = payload.first
          return value.size if key.to_s.end_with?("named_params")
          return Array(value.first).size if NESTED_ROLES.any? { |r| ROLES[r][:positional] == key }

          value.size
        end

      private

        # @raise [ArgumentError] if the role has no example key mapping.
        def keys_for(role)
          ROLES.fetch(role.to_sym) do
            raise ArgumentError, "Unknown example role: #{role.inspect}. Known roles: #{ROLES.keys.join(', ')}"
          end
        end

        # @return [Boolean] true when there is nothing to serialize.
        def blank_value?(values)
          values.nil? || (values.respond_to?(:empty?) && values.empty?)
        end

        # Whether the hash is already a built example payload rather than raw values.
        #
        # Decided by key name against the closed {BUILT_KEYS} set. A named parameter
        # that happens to be called e.g. `body_text` would be misread as a built
        # payload; that is an accepted trade for being able to paste Meta's examples.
        # @return [Boolean]
        def built?(values)
          return false unless values.is_a?(Hash)

          values.keys.map(&:to_sym).all? { |key| BUILT_KEYS.include?(key) }
        end

        # @return [Hash]
        def symbolize(values)
          values.transform_keys(&:to_sym)
        end

        # @return [Array<Hash>] Meta's `[{param_name:, example:}]` shape.
        # @raise [ArgumentError] if the values are not a usable named shape.
        def named_params(values)
          case values
          when Hash then values.map { |name, example| { param_name: name.to_s, example: } }
          when Array then values.map { |entry| named_param_entry(entry) }
          else raise ArgumentError, named_params_error(values)
          end
        end

        # @return [Hash]
        # @raise [ArgumentError] if the entry is not a param_name/example pair.
        def named_param_entry(entry)
          raise ArgumentError, named_params_error(entry) unless entry.is_a?(Hash)

          normalized = symbolize(entry)
          raise ArgumentError, named_params_error(entry) unless normalized.key?(:param_name)

          { param_name: normalized[:param_name].to_s, example: normalized[:example] }
        end

        # @return [String]
        def named_params_error(values)
          "Expected named parameter examples as a Hash of name => example, or an " \
            "array of { param_name:, example: } hashes, got: #{values.inspect}"
        end

        # @return [Array] The positional values, nested for roles that require it.
        # @raise [ArgumentError] if a Hash is given for a positional format.
        def positional_values(role, values)
          if values.is_a?(Hash)
            raise ArgumentError,
              "Expected positional parameter examples as an Array, got a Hash: #{values.inspect}. " \
                "Did you mean to set parameter_format to #{ParameterFormats::NAMED}?"
          end

          list = values.is_a?(Array) ? values : [values]
          NESTED_ROLES.include?(role.to_sym) ? [list] : list
        end
      end
    end
  end
end
