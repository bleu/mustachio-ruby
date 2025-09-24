require "spec_helper"

RSpec.describe "Comprehensive MustachioRuby Tests" do
  describe "Comments" do
    it "excludes comments from output" do
      template = "as{{!comment\ncontent}}df"
      renderer = MustachioRuby.parse(template)
      result = renderer.call({})
      expect(result).to eq("asdf")
    end

    it "handles multiline comments" do
      template = "Hello{{! this is a
      multiline comment }}World"
      renderer = MustachioRuby.parse(template)
      result = renderer.call({})
      expect(result).to eq("HelloWorld")
    end
  end

  describe "Alternative unescaped syntax {{&var}}" do
    it "handles {{&var}} syntax for unescaped content" do
      template = "Content: {{&content}}"
      renderer = MustachioRuby.parse(template)
      model = { "content" => "<b>Bold</b>" }
      result = renderer.call(model)
      expect(result).to eq("Content: <b>Bold</b>")
    end

    it "both {{{var}}} and {{&var}} work the same" do
      template1 = "Content: {{{content}}}"
      template2 = "Content: {{&content}}"

      renderer1 = MustachioRuby.parse(template1)
      renderer2 = MustachioRuby.parse(template2)

      model = { "content" => "<script>test</script>" }

      result1 = renderer1.call(model)
      result2 = renderer2.call(model)

      expect(result1).to eq(result2)
      expect(result1).to eq("Content: <script>test</script>")
    end
  end

  describe "Falsey values" do
    it "does not render falsey values in conditional sections" do
      falsey_values = [[], false, "", 0, 0.0, nil]

      falsey_values.each do |falsey_value|
        template = "{{#outer_level}}Should not render!{{inner_level}}{{/outer_level}}"
        renderer = MustachioRuby.parse(template)
        model = { "outer_level" => falsey_value }
        result = renderer.call(model)
        expect(result).to eq(""), "Failed for falsey value: #{falsey_value.inspect}"
      end
    end

    it "treats falsey values as empty arrays in each blocks" do
      falsey_values = [[], false, "", 0, 0.0, nil]

      falsey_values.each do |falsey_value|
        template = "{{#each locations}}Should not render!{{/each}}"
        renderer = MustachioRuby.parse(template)
        model = { "locations" => falsey_value }
        result = renderer.call(model)
        expect(result).to eq(""), "Failed for falsey value: #{falsey_value.inspect}"
      end
    end

    it "renders zero values in variables" do
      [0, 0.0].each do |zero_value|
        template = "You've won {{times_won}} times!"
        renderer = MustachioRuby.parse(template)
        model = { "times_won" => zero_value }
        result = renderer.call(model)
        expect(result).to eq("You've won 0 times!")
      end
    end

    it "renders false value in variables" do
      template = "You've won {{times_won}} times!"
      renderer = MustachioRuby.parse(template)
      model = { "times_won" => false }
      result = renderer.call(model)
      expect(result).to eq("You've won false times!")
    end

    it "does not render null/nil values" do
      template = "You've won {{times_won}} times!"
      renderer = MustachioRuby.parse(template)
      model = { "times_won" => nil }
      result = renderer.call(model)
      expect(result).to eq("You've won  times!")
    end
  end

  describe "Parent navigation with ../" do
    it "handles complex each with parent navigation" do
      template = "{{#each Company.ceo.products}}<li>{{ name }} and {{version}} and has a CEO: {{../../last_name}}</li>{{/each}}"
      renderer = MustachioRuby.parse(template)

      model = {
        "Company" => {
          "ceo" => {
            "last_name" => "Smith",
            "products" => [
              { "name" => "name 0", "version" => "version 0" },
              { "name" => "name 1", "version" => "version 1" },
              { "name" => "name 2", "version" => "version 2" }
            ]
          }
        }
      }

      result = renderer.call(model)
      expected = "<li>name 0 and version 0 and has a CEO: Smith</li>" +
                 "<li>name 1 and version 1 and has a CEO: Smith</li>" +
                 "<li>name 2 and version 2 and has a CEO: Smith</li>"
      expect(result).to eq(expected)
    end

    it "processes variables in inverted groups with parent navigation" do
      template = "{{^not_here}}{{../placeholder}}{{/not_here}}"
      renderer = MustachioRuby.parse(template)

      model = {
        "not_here" => false,
        "placeholder" => "a placeholder value"
      }

      result = renderer.call(model)
      expect(result).to eq("a placeholder value")
    end
  end

  describe "Unsigned integer types" do
    it "supports various numeric types" do
      template = "{{uint}};{{ushort}};{{ulong}}"
      renderer = MustachioRuby.parse(template)

      model = {
        "uint" => 123,
        "ushort" => 234,
        "ulong" => 18446744073709551615  # max value
      }

      result = renderer.call(model)
      expect(result).to eq("123;234;18446744073709551615")
    end
  end

  describe "Content safety options" do
    it "can disable HTML escaping globally" do
      template = "{{content}}"

      options = MustachioRuby::ParsingOptions.new
      options.disable_content_safety = true

      renderer = MustachioRuby.parse(template, options)
      model = { "content" => "<script>alert('test')</script>" }
      result = renderer.call(model)

      expect(result).to eq("<script>alert('test')</script>")
    end

    it "treats both {{var}} and {{{var}}} the same when safety disabled" do
      options = MustachioRuby::ParsingOptions.new
      options.disable_content_safety = true

      template1 = "{{content}}"
      template2 = "{{{content}}}"

      renderer1 = MustachioRuby.parse(template1, options)
      renderer2 = MustachioRuby.parse(template2, options)

      model = { "content" => "<wbr>" }

      result1 = renderer1.call(model)
      result2 = renderer2.call(model)

      expect(result1).to eq("<wbr>")
      expect(result2).to eq("<wbr>")
      expect(result1).to eq(result2)
    end
  end

  describe "Template with no variables" do
    it "renders plain text with no variables" do
      template = "ASDF"
      renderer = MustachioRuby.parse(template)
      result = renderer.call(nil)
      expect(result).to eq("ASDF")
    end

    it "handles templates with no mustache markup" do
      template = "This template has no mustache thingies."
      info = MustachioRuby.parse_with_model_inference(template)

      # Should have empty model inference
      expect(info.inferred_model.children).to be_empty

      result = info.parsed_template.call({})
      expect(result).to eq("This template has no mustache thingies.")
    end
  end

  describe "Complex paths" do
    it "handles complex nested paths" do
      template = "{{#content}}Hello {{../Person.Name}}!{{/content}}"
      renderer = MustachioRuby.parse(template)

      model = {
        "content" => true,
        "Person" => {
          "Name" => "World"
        }
      }

      result = renderer.call(model)
      expect(result).to eq("Hello World!")
    end
  end

  describe "Partial mustache syntax" do
    it "handles partial open and close braces as literal text" do
      test_cases = [
        ["{{Mike", "{{{{name}}"],
        ["{Mike", "{{{name}}"],
        ["Mike}", "{{name}}}"],
        ["Mike}}", "{{name}}}}"]
      ]

      model = { "name" => "Mike" }

      test_cases.each do |expected, template|
        renderer = MustachioRuby.parse(template)
        result = renderer.call(model)
        expect(result).to eq(expected), "Failed for template: #{template}"
      end
    end
  end
end
