module MustachioRuby
  module TokenType
    ESCAPED_SINGLE_VALUE = :escaped_single_value
    UNESCAPED_SINGLE_VALUE = :unescaped_single_value
    INVERTED_ELEMENT_OPEN = :inverted_element_open
    ELEMENT_OPEN = :element_open
    ELEMENT_CLOSE = :element_close
    COMMENT = :comment
    CONTENT = :content
    COLLECTION_OPEN = :collection_open
    COLLECTION_CLOSE = :collection_close
    CUSTOM = :custom
  end

  class TokenTuple
    attr_accessor :type, :value, :renderer

    def initialize(type, value, renderer = nil)
      @type = type
      @value = value
      @renderer = renderer
    end

    def to_s
      "#{@type}, #{@value}"
    end
  end
end
