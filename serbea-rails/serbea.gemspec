# frozen_string_literal: true

require_relative "lib/version"

Gem::Specification.new do |spec|
  spec.name          = "serbea-rails"
  spec.version       = SerbeaRails::VERSION
  spec.author        = "Bridgetown Team"
  spec.email         = "maintainers@bridgetownrb.com"
  spec.summary       = "Rails plugin for Serbea"
  spec.homepage      = "https://github.com/bridgetownrb/serbea"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.7"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r!^(test|script|spec|features)/!) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency("serbea", ">= 1.0")
  spec.add_runtime_dependency("activesupport", ">= 6.0")
  spec.add_runtime_dependency("actionview", ">= 6.0")
  spec.add_runtime_dependency("hash_with_dot_access", "~> 1.1")

  spec.add_development_dependency("rake", "~> 13.0")
end
