# MustachioRuby

A Ruby port of the powerful [Mustachio](https://github.com/ActiveCampaign/mustachio) templating engine for C# and .NET - a lightweight, fast, and safe templating engine with model inference capabilities.

> **Note**: This is an unofficial Ruby port of the original [Mustachio](https://github.com/ActiveCampaign/mustachio) templating engine created by ActiveCampaign. All credit for the original design, concepts, and innovations goes to the ActiveCampaign team and the Mustachio contributors.

#### What's this for?

_MustachioRuby_ allows you to create simple text-based templates that are fast and safe to render. It's a Ruby implementation that brings the power of the templating engine behind [Postmark Templates](https://postmarkapp.com/blog/special-delivery-postmark-templates) to the Ruby ecosystem.

#### How to use MustachioRuby:

```ruby
# Parse the template:
source_template = "Dear {{name}}, this is definitely a personalized note to you. Very truly yours, {{sender}}"
template = MustachioRuby.parse(source_template)

# Create the values for the template model:
model = {
  "name" => "John",
  "sender" => "Sally"
}

# Combine the model with the template to get content:
content = template.call(model)
# => "Dear John, this is definitely a personalized note to you. Very truly yours, Sally"
```

#### Extending MustachioRuby with Token Expanders:

```ruby
# You can add support for Partials via Token Expanders.
# Token Expanders can be used to extend MustachioRuby for many other use cases,
# such as: Date/Time formatters, Localization, etc., allowing also custom Token Render functions.

source_template = "Welcome to our website! [[CONTENT]] Yours Truly, John Smith."
string_data = "This is a partial. You can also add variables here {{ testVar }} or use other expanders. Watch out for infinite loops!"

token_expander = MustachioRuby::TokenExpander.new
token_expander.regex = /\[\[CONTENT\]\]/ # Custom syntax to avoid conflicts
token_expander.expand_tokens = lambda do |s, base_options|
  # Create new ParsingOptions to avoid infinite loops
  new_options = MustachioRuby::ParsingOptions.new
  MustachioRuby::Tokenizer.tokenize(string_data, new_options)
end

parsing_options = MustachioRuby::ParsingOptions.new
parsing_options.token_expanders = [token_expander]
template = MustachioRuby.parse(source_template, parsing_options)

# Create the values for the template model:
model = { "testVar" => "Test" }

# Combine the model with the template to get content:
content = template.call(model)
```

#### Installing MustachioRuby:

MustachioRuby can be installed via [RubyGems](https://rubygems.org/):

```bash
gem install mustachio_ruby
```

Or add this line to your application's Gemfile:

```ruby
gem 'mustachio_ruby'
```

And then execute:

    $ bundle install

## Usage Examples

### Working with Arrays using `each` blocks:

```ruby
template = "{{#each items}}Item: {{name}} - ${{price}}\n{{/each}}"
renderer = MustachioRuby.parse(template)

model = {
  "items" => [
    { "name" => "Apple", "price" => 1.50 },
    { "name" => "Banana", "price" => 0.75 }
  ]
}

content = renderer.call(model)
# => "Item: Apple - $1.5\nItem: Banana - $0.75\n"
```

### Complex Paths for Nested Objects:

```ruby
template = "User: {{user.profile.name}} ({{user.profile.age}}) from {{user.location.city}}, {{user.location.country}}"
renderer = MustachioRuby.parse(template)

model = {
  "user" => {
    "profile" => { "name" => "Alice Smith", "age" => 30 },
    "location" => { "city" => "New York", "country" => "USA" }
  }
}

content = renderer.call(model)
# => "User: Alice Smith (30) from New York, USA"
```

### Conditional Sections:

```ruby
template = "{{#showMessage}}Hello, {{name}}!{{/showMessage}}{{^showMessage}}Goodbye!{{/showMessage}}"
renderer = MustachioRuby.parse(template)

# When showMessage is true
model = { "showMessage" => true, "name" => "World" }
content = renderer.call(model)
# => "Hello, World!"

# When showMessage is false
model = { "showMessage" => false, "name" => "World" }
content = renderer.call(model)
# => "Goodbye!"
```

### HTML Escaping (Safe by Default):

```ruby
# Escaped by default for safety
template = "Content: {{html}}"
renderer = MustachioRuby.parse(template)
model = { "html" => "<script>alert('xss')</script>" }
content = renderer.call(model)
# => "Content: &lt;script&gt;alert('xss')&lt;/script&gt;"

# Unescaped with triple braces
template = "Content: {{{html}}}"
renderer = MustachioRuby.parse(template)
content = renderer.call(model)
# => "Content: <script>alert('xss')</script>"
```

### Model Inference:

```ruby
template = "Hello {{name}}! You have {{#each orders}}{{total}}{{/each}} orders."
result = MustachioRuby.parse_with_model_inference(template)

# result.parsed_template is the compiled template function
# result.inferred_model contains information about expected model structure
model = { "name" => "Alice", "orders" => [{ "total" => 5 }, { "total" => 3 }] }
content = result.parsed_template.call(model)
# => "Hello Alice! You have 53 orders."
```

### Advanced: Parsing Options

```ruby
options = MustachioRuby::ParsingOptions.new
options.disable_content_safety = true  # Disable HTML escaping
options.source_name = "my_template"    # For error reporting

template = "Unsafe content: {{html}}"
renderer = MustachioRuby.parse(template, options)
model = { "html" => "<b>Bold Text</b>" }
content = renderer.call(model)
# => "Unsafe content: <b>Bold Text</b>"
```

##### Key differences between Mustachio and [Mustache](https://mustache.github.io/)

MustachioRuby contains a few modifications to the core Mustache language that are important:

1. `each` blocks are recommended for handling arrays of values. (We have a good reason!)
2. Complex paths are supported, for example `{{ this.is.a.valid.path }}` and `{{ ../this.goes.up.one.level }}`
3. Template partials are supported via Token Expanders.

###### A little more about the differences:

One awesome feature of Mustachio is that with a minor alteration in the mustache syntax, we can infer what model will be required to completely fill out a template. By using the `each` keyword when iterating over an array, our parser can infer whether an array or object (or scalar) should be expected when the template is used. Normal mustache syntax would prevent us from determining this.

We think the model inference feature is compelling, because it allows for error detection, and faster debugging iterations when developing templates, which justifies this minor change to 'vanilla' mustache syntax.

## Development

After checking out the repo, run:

```bash
bundle install
bundle exec rspec
```

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Acknowledgments

This Ruby port would not be possible without the incredible work of the original [Mustachio](https://github.com/ActiveCampaign/mustachio) team at ActiveCampaign. Special thanks to:

- **ActiveCampaign Team**: For creating and maintaining the original Mustachio templating engine
- **All Mustachio Contributors**: For their valuable contributions to the original project
- **Postmark Team**: For demonstrating the power of this templating approach in production

MustachioRuby aims to faithfully port the original concepts and functionality while adapting them to Ruby's idioms and conventions.

## License

The gem is available as open source under the [MIT License](LICENSE).
