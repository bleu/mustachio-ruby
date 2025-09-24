module MustachioRuby
  class IndexedParseException < StandardError
    attr_reader :source_name, :line_number, :character_on_line

    def initialize(source_name, location, message, *args)
      @source_name = source_name
      @line_number = location ? location[:line] : 0
      @character_on_line = location ? location[:character] : 0

      formatted_message = message % args
      super("#{source_name} Line: #{@line_number} Column: #{@character_on_line} #{formatted_message}")
    end
  end
end
