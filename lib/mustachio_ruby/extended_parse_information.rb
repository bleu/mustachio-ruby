module MustachioRuby
  class ExtendedParseInformation
    attr_accessor :inferred_model, :parsed_template

    def initialize
      @inferred_model = nil
      @parsed_template = nil
    end
  end
end
