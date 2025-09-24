# frozen_string_literal: true

require_relative "lib/mustachio_ruby/version"

Gem::Specification.new do |spec|
  spec.name = "mustachio-ruby"
  spec.version = MustachioRuby::VERSION
  spec.authors = ["João Victor Assis"]
  spec.email = ["joaovictorass95@gmail.com"]
  spec.license = "MIT"

  spec.summary = "A powerful templating engine for Ruby"
  spec.description = "A Ruby port of the Postmark C# Mustachio templating engine with model inference and extensible token support"
  spec.homepage = "https://github.com/bleu/mustachio-ruby"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bleu/mustachio-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/bleu/mustachio-ruby/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake", "~> 13.0"

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
