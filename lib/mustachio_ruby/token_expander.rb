module MustachioRuby
  module Precedence
    LOW = :low
    MEDIUM = :medium
    HIGH = :high
  end

  class TokenExpander
    attr_accessor :regex, :precedence, :expand_tokens, :renderer

    def initialize
      @precedence = Precedence::MEDIUM
    end
  end
end
