module MustachioRuby
  class Tokenizer
    TOKEN_FINDER = /(\{\{[^{}]+?\}\})|(\{\{\{[^{}]+?\}\}\})/
    NEWLINE_FINDER = /\n/
    NEGATIVE_PATH_SPEC = /(\.{3,})|([^\w.\/_]+)|((?<!\.{2})[\/])|(\.{2,}($|[^\/]))/

    def self.tokenize(template_string, parsing_options)
      template_string ||= ""
      matches = template_string.scan(TOKEN_FINDER).flatten.compact
      scope_stack = []
      source_name = parsing_options.source_name

      idx = 0
      tokens = []
      parse_errors = []
      lines = nil

      template_string.scan(/(\{\{[^{}]+?\}\})|(\{\{\{[^{}]+?\}\}\})/) do |match|
        token_match = match.compact.first
        match_start = $~.begin(0)

        # Add content before token
        if match_start > idx
          content = template_string[idx...match_start]
          tokens << TokenTuple.new(TokenType::CONTENT, content)
        end

        process_token(token_match, match_start, template_string, tokens, parse_errors,
                     scope_stack, source_name, parsing_options, lines)

        idx = match_start + token_match.length
      end

      # Add remaining content
      if idx < template_string.length
        tokens << TokenTuple.new(TokenType::CONTENT, template_string[idx..-1])
      end

      # Check for unclosed scopes
      unless scope_stack.empty?
        scope_stack.reverse.each do |scope_info|
          value = scope_info[:value].gsub(/[\{\}#]/, '').strip
          value = value.sub(/^each /, '') if value.start_with?('each ')
          location = humanize_character_location(template_string, scope_info[:index], lines)

          parse_errors << IndexedParseException.new(
            source_name,
            location,
            "A scope block to the following path was opened but not closed: '%s', please close it using the appropriate syntax.",
            value
          )
        end
      end

      result = TokenizeResult.new
      result.tokens = tokens
      result.errors = parse_errors
      result
    end

    private

    def self.process_token(token_match, match_start, template_string, tokens, parse_errors,
                          scope_stack, source_name, parsing_options, lines)

      if token_match.match?(/^{{#each(\s|$)/)
        handle_each_open(token_match, match_start, template_string, tokens, parse_errors,
                        scope_stack, source_name, lines)
      elsif token_match == "{{/each}}"
        handle_each_close(token_match, match_start, template_string, tokens, parse_errors,
                         scope_stack, source_name, lines)
      elsif token_match.start_with?("{{#")
        handle_element_open(token_match, match_start, template_string, tokens, parse_errors,
                           scope_stack, source_name, lines)
      elsif token_match.start_with?("{{^")
        handle_inverted_element_open(token_match, match_start, template_string, tokens,
                                   parse_errors, scope_stack, source_name, lines)
      elsif token_match.start_with?("{{/")
        handle_element_close(token_match, match_start, template_string, tokens, parse_errors,
                            scope_stack, source_name, lines)
      elsif token_match.start_with?("{{{") || token_match.start_with?("{{&")
        handle_unescaped_value(token_match, match_start, template_string, tokens,
                              parse_errors, source_name, lines)
      elsif token_match.start_with?("{{!")
        # Comment - ignore
      else
        handle_escaped_value(token_match, match_start, template_string, tokens,
                            parse_errors, source_name, lines)
      end
    end

    def self.handle_each_open(token_match, match_start, template_string, tokens, parse_errors,
                             scope_stack, source_name, lines)
      scope_stack << { value: token_match, index: match_start }
      token_value = token_match.gsub(/[\{\}#]/, '').strip
      token_value = token_value.sub(/^each/, '').strip

      if token_value.empty?
        location = humanize_character_location(template_string, match_start, lines)
        parse_errors << IndexedParseException.new(
          source_name,
          location,
          "The 'each' block being opened requires a model path to be specified in the form '{{#each <name>}}'."
        )
      else
        validated_token = validate_token(token_value, template_string, match_start,
                                       source_name, lines, parse_errors)
        tokens << TokenTuple.new(TokenType::COLLECTION_OPEN, validated_token)
      end
    end

    def self.handle_each_close(token_match, match_start, template_string, tokens, parse_errors,
                              scope_stack, source_name, lines)
      if !scope_stack.empty? && scope_stack.last[:value].match?(/^{{#each(\s|$)/)
        scope_info = scope_stack.pop
        tokens << TokenTuple.new(TokenType::COLLECTION_CLOSE, scope_info[:value])
      else
        location = humanize_character_location(template_string, match_start, lines)
        parse_errors << IndexedParseException.new(
          source_name,
          location,
          "An 'each' block is being closed, but no corresponding opening element ('{{#each <name>}}') was detected."
        )
      end
    end

    def self.handle_element_open(token_match, match_start, template_string, tokens, parse_errors,
                                scope_stack, source_name, lines)
      token_value = token_match.gsub(/[\{\}#]/, '').strip

      if !scope_stack.empty? && scope_stack.last[:value] == token_value
        validated_token = validate_token(token_value, template_string, match_start,
                                       source_name, lines, parse_errors)
        tokens << TokenTuple.new(TokenType::ELEMENT_CLOSE, validated_token)
      else
        scope_stack << { value: token_value, index: match_start }
      end

      validated_token = validate_token(token_value, template_string, match_start,
                                     source_name, lines, parse_errors)
      tokens << TokenTuple.new(TokenType::ELEMENT_OPEN, validated_token)
    end

    def self.handle_inverted_element_open(token_match, match_start, template_string, tokens,
                                         parse_errors, scope_stack, source_name, lines)
      token_value = token_match.gsub(/[\{\}\^]/, '').strip

      if !scope_stack.empty? && scope_stack.last[:value] == token_value
        validated_token = validate_token(token_value, template_string, match_start,
                                       source_name, lines, parse_errors)
        tokens << TokenTuple.new(TokenType::ELEMENT_CLOSE, validated_token)
      else
        scope_stack << { value: token_value, index: match_start }
      end

      validated_token = validate_token(token_value, template_string, match_start,
                                     source_name, lines, parse_errors)
      tokens << TokenTuple.new(TokenType::INVERTED_ELEMENT_OPEN, validated_token)
    end

    def self.handle_element_close(token_match, match_start, template_string, tokens, parse_errors,
                                 scope_stack, source_name, lines)
      token_value = token_match.gsub(/[\{\}\/]/, '').strip

      if !scope_stack.empty? && scope_stack.last[:value] == token_value
        scope_stack.pop
        validated_token = validate_token(token_value, template_string, match_start,
                                       source_name, lines, parse_errors)
        tokens << TokenTuple.new(TokenType::ELEMENT_CLOSE, validated_token)
      else
        location = humanize_character_location(template_string, match_start, lines)
        parse_errors << IndexedParseException.new(
          source_name,
          location,
          "It appears that open and closing elements are mismatched."
        )
      end
    end

    def self.handle_unescaped_value(token_match, match_start, template_string, tokens,
                                   parse_errors, source_name, lines)
      token_value = token_match.gsub(/[\{\}&]/, '').strip
      validated_token = validate_token(token_value, template_string, match_start,
                                     source_name, lines, parse_errors)
      tokens << TokenTuple.new(TokenType::UNESCAPED_SINGLE_VALUE, validated_token)
    end

    def self.handle_escaped_value(token_match, match_start, template_string, tokens,
                                 parse_errors, source_name, lines)
      token_value = token_match.gsub(/[\{\}]/, '').strip
      validated_token = validate_token(token_value, template_string, match_start,
                                     source_name, lines, parse_errors)
      tokens << TokenTuple.new(TokenType::ESCAPED_SINGLE_VALUE, validated_token)
    end

    def self.validate_token(token, content, index, source_name, lines, exceptions)
      token = token.strip

      if NEGATIVE_PATH_SPEC.match(token)
        location = humanize_character_location(content, index, lines)
        exceptions << IndexedParseException.new(
          source_name,
          location,
          "The path '%s' is not valid. Please see documentation for examples of valid paths.",
          token
        )
      end

      token
    end

    def self.humanize_character_location(content, character_index, lines)
      lines ||= content.enum_for(:scan, NEWLINE_FINDER).map { Regexp.last_match.begin(0) }

      line = lines.bsearch_index { |pos| pos > character_index } || lines.length
      char_idx = character_index

      if line > 0 && line <= lines.length
        char_idx = character_index - (lines[line - 1] + 1)
      elsif line > 0
        char_idx = character_index - (lines.last + 1) if !lines.empty?
      end

      {
        line: line + 1,
        character: char_idx + 1
      }
    end
  end
end
