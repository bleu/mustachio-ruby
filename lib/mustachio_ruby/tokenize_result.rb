module MustachioRuby
  class TokenizeResult
    attr_accessor :tokens, :errors

    def initialize
      @tokens = []
      @errors = []
    end
  end
end
