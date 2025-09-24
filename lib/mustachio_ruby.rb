# frozen_string_literal: true

require_relative "mustachio_ruby/version"
require_relative "mustachio_ruby/parser"
require_relative "mustachio_ruby/tokenizer"
require_relative "mustachio_ruby/context_object"
require_relative "mustachio_ruby/parsing_options"
require_relative "mustachio_ruby/token_tuple"
require_relative "mustachio_ruby/token_expander"
require_relative "mustachio_ruby/tokenize_result"
require_relative "mustachio_ruby/inferred_template_model"
require_relative "mustachio_ruby/extended_parse_information"
require_relative "mustachio_ruby/indexed_parse_exception"

module MustachioRuby
  class << self
    def parse(template, options = ParsingOptions.new)
      Parser.parse(template, options)
    end

    def parse_with_model_inference(template, options = ParsingOptions.new)
      Parser.parse_with_model_inference(template, options)
    end
  end
end
