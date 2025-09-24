require "cgi"

module MustachioRuby
  class ContextObject
    PATH_FINDER = /(\.\.[\\\/]{1})|([^.]+)/

    attr_accessor :parent, :value, :key

    def initialize
      @parent = nil
      @value = nil
      @key = ""
    end

    def get_context_for_path(path)
      elements = path.scan(PATH_FINDER).map { |match| match.compact.first }
      get_context_for_path_elements(elements)
    end

    def exists?
      return false if @value.nil?
      return false if @value == false
      return false if @value == 0
      return false if @value == 0.0
      return false if @value == ""

      if @value.respond_to?(:empty?)
        return !@value.empty?
      end

      true
    end

    def to_s
      return "" if @value.nil?

      case @value
      when String
        @value.to_s
      when Integer
        @value.to_s
      when Float
        # Format floats like integers when they're whole numbers
        @value == @value.to_i ? @value.to_i.to_s : @value.to_s
      when TrueClass, FalseClass
        @value.to_s
      else
        ""
      end
    end

    def get_context_for_path_elements(elements)
      return self if elements.empty?

      element = elements.shift

      if element&.start_with?("..")
        if @parent
          @parent.get_context_for_path_elements(elements)
        else
          get_context_for_path_elements(elements)
        end
      else
        inner_context = ContextObject.new
        inner_context.key = element
        inner_context.parent = self

        if @value.respond_to?(:[])
          begin
            inner_context.value = @value[element]
          rescue
            inner_context.value = nil
          end
        end

        inner_context.get_context_for_path_elements(elements)
      end
    end
  end
end
