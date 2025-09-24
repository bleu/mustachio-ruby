require "spec_helper"

RSpec.describe MustachioRuby do
  describe ".parse" do
    it "parses a simple template" do
      template = "Dear {{name}}, this is definitely a personalized note to you. Very truly yours, {{sender}}"
      renderer = MustachioRuby.parse(template)

      model = {
        "name" => "John",
        "sender" => "Sally"
      }

      result = renderer.call(model)
      expect(result).to eq("Dear John, this is definitely a personalized note to you. Very truly yours, Sally")
    end

    it "handles missing values gracefully" do
      template = "Hello {{name}}!"
      renderer = MustachioRuby.parse(template)

      result = renderer.call({})
      expect(result).to eq("Hello !")
    end

    it "handles HTML escaping by default" do
      template = "Content: {{content}}"
      renderer = MustachioRuby.parse(template)

      model = { "content" => "<script>alert('xss')</script>" }
      result = renderer.call(model)

      expect(result).to eq("Content: &lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
    end

    it "handles unescaped content with triple braces" do
      template = "Content: {{{content}}}"
      renderer = MustachioRuby.parse(template)

      model = { "content" => "<b>Bold</b>" }
      result = renderer.call(model)

      expect(result).to eq("Content: <b>Bold</b>")
    end

    it "handles each blocks for arrays" do
      template = "{{#each items}}Item: {{.}}{{/each}}"
      renderer = MustachioRuby.parse(template)

      model = { "items" => ["apple", "banana", "cherry"] }
      result = renderer.call(model)

      expect(result).to eq("Item: appleItem: bananaItem: cherry")
    end

    it "handles conditional sections" do
      template = "{{#showSection}}This section is shown!{{/showSection}}"
      renderer = MustachioRuby.parse(template)

      model = { "showSection" => true }
      result = renderer.call(model)

      expect(result).to eq("This section is shown!")
    end

    it "handles inverted sections" do
      template = "{{^hideSection}}This section is shown!{{/hideSection}}"
      renderer = MustachioRuby.parse(template)

      model = { "hideSection" => false }
      result = renderer.call(model)

      expect(result).to eq("This section is shown!")
    end

    it "handles nested object paths" do
      template = "Hello {{user.profile.name}}!"
      renderer = MustachioRuby.parse(template)

      model = {
        "user" => {
          "profile" => {
            "name" => "Alice"
          }
        }
      }
      result = renderer.call(model)

      expect(result).to eq("Hello Alice!")
    end
  end

  describe ".parse_with_model_inference" do
    it "returns both template and inferred model" do
      template = "Hello {{name}}! Age: {{age}}"
      result = MustachioRuby.parse_with_model_inference(template)

      expect(result).to be_a(MustachioRuby::ExtendedParseInformation)
      expect(result.parsed_template).to be_a(Proc)
      expect(result.inferred_model).to be_a(MustachioRuby::InferredTemplateModel)
    end
  end
end
