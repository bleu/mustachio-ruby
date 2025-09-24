module MustachioRuby
  class ParsingOptions
    attr_accessor :disable_content_safety, :source_name, :token_expanders

    def initialize
      @disable_content_safety = false
      @source_name = ""
      @token_expanders = []
    end
  end
end
