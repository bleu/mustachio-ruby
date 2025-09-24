require "spec_helper"

RSpec.describe "Error Handling Tests" do
  describe "Invalid paths" do
    invalid_paths = [
      "{{.../asdf.content}}",
      "{{/}}",
      "{{./}}",
      "{{.. }}",
      "{{..}}",
      "{{//}}",
      "{{@}}",
      "{{[}}",
      "{{]}}",
      "{{)}}",
      "{{(}}",
      "{{~}}",
      "{{$}}",
      "{{%}}"
    ]

    invalid_paths.each do |invalid_path|
      it "should throw for invalid path: #{invalid_path}" do
        expect { MustachioRuby.parse(invalid_path) }.to raise_error(MustachioRuby::IndexedParseException)
      end
    end
  end

  describe "Valid paths" do
    valid_paths = [
      "{{first_name}}",
      "{{company.name}}",
      "{{company.address_line_1}}",
      "{{name}}"
    ]

    valid_paths.each do |valid_path|
      it "should not throw for valid path: #{valid_path}" do
        expect { MustachioRuby.parse(valid_path) }.not_to raise_error
      end
    end
  end

  describe "Mismatched groups" do
    it "throws for mismatched conditional groups" do
      template = "{{#Collection}}Collection has elements{{/AnotherCollection}}"
      expect { MustachioRuby.parse(template) }.to raise_error(MustachioRuby::IndexedParseException)
    end

    mismatched_each_templates = [
      "{{#ACollection}}{{.}}{{/each}}",
      "{{#ACollection}}{{.}}{{/ACollection}}{{/each}}",
      "{{/each}}"
    ]

    mismatched_each_templates.each do |template|
      it "throws for mismatched each: #{template}" do
        expect { MustachioRuby.parse(template) }.to raise_error(MustachioRuby::IndexedParseException)
      end
    end

    unclosed_groups = [
      "{{#each element}}{{name}}",
      "{{#element}}{{name}}",
      "{{^element}}{{name}}"
    ]

    unclosed_groups.each do |template|
      it "throws for unclosed group: #{template}" do
        expect { MustachioRuby.parse(template) }.to raise_error(MustachioRuby::IndexedParseException)
      end
    end
  end

  describe "Empty each" do
    it "throws for empty each block" do
      expect { MustachioRuby.parse("{{#each}}") }.to raise_error(MustachioRuby::IndexedParseException)
    end

    it "throws for each without path" do
      expect { MustachioRuby.parse("{{#eachs}}{{name}}{{/each}}") }.to raise_error(MustachioRuby::IndexedParseException)
    end
  end

  describe "Character location information" do
    it "provides character location for parse errors" do
      template = "1{{first name}}"

      begin
        MustachioRuby.parse(template)
        fail "Expected IndexedParseException to be thrown"
      rescue MustachioRuby::IndexedParseException => e
        expect(e.line_number).to be > 0
        expect(e.character_on_line).to be > 0
        expect(e.message).to include("Line:")
        expect(e.message).to include("Column:")
      end
    end

    it "handles multiline templates with errors" do
      template = "ss{{#each company.name}}\nasdf"

      begin
        MustachioRuby.parse(template)
        fail "Expected IndexedParseException to be thrown"
      rescue MustachioRuby::IndexedParseException => e
        expect(e.line_number).to be > 0
        expect(e.character_on_line).to be > 0
      end
    end
  end

  describe "Source names in errors" do
    it "includes source names in parse errors" do
      template = "Hello, {{##each}}!!!"
      source_name = "TestBase"

      options = MustachioRuby::ParsingOptions.new
      options.source_name = source_name

      begin
        MustachioRuby.parse(template, options)
        fail "Expected IndexedParseException to be thrown"
      rescue MustachioRuby::IndexedParseException => e
        expect(e.source_name).to eq(source_name)
        expect(e.message).to include(source_name)
      end
    end
  end
end
