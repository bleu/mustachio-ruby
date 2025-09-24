require "cgi"

module MustachioRuby
  class Parser
    def self.parse(template, options = ParsingOptions.new)
      tokens_result = get_tokens_queue(template, options)
      if !tokens_result.errors.empty?
        raise tokens_result.errors.first
      end

      internal_template = parse_tokens(tokens_result.tokens, options)

      lambda do |model|
        output = ""
        context = ContextObject.new
        context.value = model
        context.key = ""

        internal_template.call(output, context)
        output
      end
    end

    def self.parse_with_model_inference(template_source, options = ParsingOptions.new)
      tokens_result = get_tokens_queue(template_source, options)
      if !tokens_result.errors.empty?
        raise tokens_result.errors.first
      end

      inferred_model = InferredTemplateModel.new
      internal_template = parse_tokens(tokens_result.tokens, options, inferred_model)

      template = lambda do |model|
        output = ""
        context = ContextObject.new
        context.value = model
        context.key = ""

        internal_template.call(output, context)
        output
      end

      result = ExtendedParseInformation.new
      result.inferred_model = inferred_model
      result.parsed_template = template
      result
    end

    private

    def self.get_tokens_queue(template, options)
      Tokenizer.tokenize(template, options)
    end

    def self.parse_tokens(tokens, options, current_scope = nil)
      build_array = []

      while !tokens.empty?
        current_token = tokens.shift

        case current_token.type
        when TokenType::COMMENT
          # Skip comments
        when TokenType::CONTENT
          build_array << handle_content(current_token.value)
        when TokenType::COLLECTION_OPEN
          build_array << handle_collection_open(current_token, tokens, options, current_scope)
        when TokenType::ELEMENT_OPEN
          build_array << handle_element_open(current_token, tokens, options, current_scope)
        when TokenType::INVERTED_ELEMENT_OPEN
          build_array << handle_inverted_element_open(current_token, tokens, options, current_scope)
        when TokenType::COLLECTION_CLOSE, TokenType::ELEMENT_CLOSE
          # Return current template function
          return lambda do |output, context|
            build_array.each { |action| action.call(output, context) }
          end
        when TokenType::ESCAPED_SINGLE_VALUE, TokenType::UNESCAPED_SINGLE_VALUE
          build_array << handle_single_value(current_token, options, current_scope)
        when TokenType::CUSTOM
          if current_token.renderer
            build_array << current_token.renderer.call(current_token.value, tokens, options, current_scope)
          end
        end
      end

      lambda do |output, context|
        build_array.each { |action| action.call(output, context) }
      end
    end

    def self.html_encode_string(content)
      CGI.escapeHTML(content)
    end

    def self.handle_single_value(token, options, scope)
      if scope
        scope.get_inferred_model_for_path(token.value, UsedAs::SCALAR)
      end

      lambda do |output, context|
        if context
          c = context.get_context_for_path(token.value)
          unless c.value.nil?
            if token.type == TokenType::ESCAPED_SINGLE_VALUE && !options.disable_content_safety
              output << html_encode_string(c.to_s)
            else
              output << c.to_s
            end
          end
        end
      end
    end

    def self.handle_content(token)
      lambda { |output, context| output << token }
    end

    def self.handle_inverted_element_open(token, remainder, options, scope)
      if scope
        scope.get_inferred_model_for_path(token.value, UsedAs::CONDITIONAL_VALUE)
      end

      inner_template = parse_tokens(remainder, options, scope)

      lambda do |output, context|
        c = context.get_context_for_path(token.value)
        unless c.exists?
          inner_template.call(output, c)
        end
      end
    end

    def self.handle_collection_open(token, remainder, options, scope)
      if scope
        scope.get_inferred_model_for_path(token.value, UsedAs::COLLECTION)
      end

      inner_template = parse_tokens(remainder, options, scope)

      lambda do |output, context|
        c = context.get_context_for_path(token.value)
        return unless c.exists?

        if c.value.is_a?(Array)
          # Handle arrays
          index = 0
          c.value.each do |item|
            inner_context = ContextObject.new
            inner_context.value = item
            inner_context.key = "[#{index}]"
            inner_context.parent = c

            inner_template.call(output, inner_context)
            index += 1
          end
        elsif c.value.respond_to?(:each) && !c.value.is_a?(String)
          # Handle other enumerable objects (like hashes)
          if c.value.respond_to?(:keys)
            # Hash-like objects
            index = 0
            c.value.each do |key, item|
              inner_context = ContextObject.new
              inner_context.value = item
              inner_context.key = "[#{index}]"
              inner_context.parent = c

              inner_template.call(output, inner_context)
              index += 1
            end
          else
            # Other enumerable objects
            index = 0
            c.value.each do |item|
              inner_context = ContextObject.new
              inner_context.value = item
              inner_context.key = "[#{index}]"
              inner_context.parent = c

              inner_template.call(output, inner_context)
              index += 1
            end
          end
        else
          raise IndexedParseException.new(
            "",
            nil,
            "'%s' is used like an array by the template, but is a scalar value or object in your model.",
            token.value
          )
        end
      end
    end

    def self.handle_element_open(token, remainder, options, scope)
      if scope
        scope.get_inferred_model_for_path(token.value, UsedAs::CONDITIONAL_VALUE)
      end

      inner_template = parse_tokens(remainder, options, scope)

      lambda do |output, context|
        c = context.get_context_for_path(token.value)
        if c.exists?
          inner_template.call(output, c)
        end
      end
    end
  end
end
