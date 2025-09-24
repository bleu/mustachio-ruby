module MustachioRuby
  module UsedAs
    SCALAR = :scalar
    COLLECTION = :collection
    CONDITIONAL_VALUE = :conditional_value
  end

  class InferredTemplateModel
    attr_accessor :used_as, :children

    def initialize
      @children = {}
      @used_as = nil
    end

    def get_inferred_model_for_path(path, usage)
      path_parts = path.split('.')
      current = self

      path_parts.each do |part|
        current.children[part] ||= InferredTemplateModel.new
        current = current.children[part]
      end

      current.used_as = usage if current.used_as.nil?
      current
    end
  end
end
