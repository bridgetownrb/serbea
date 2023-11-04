# frozen_string_literal: true

require_relative "lib/version"

Gem::Specification.new do |spec|
  spec.name          = "serbea"
  spec.version       = Serbea::VERSION
  spec.author        = "Bridgetown Team"
  spec.email         = "maintainers@bridgetownrb.com"
  spec.summary       = "Similar to ERB, Except Awesomer"
  spec.homepage      = "https://github.com/bridgetownrb/serbea"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.7"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r!^(test|script|spec|features|docs|serbea-rails)/!) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency("erubi", ">= 1.10")
  spec.add_runtime_dependency("tilt", "~> 2.0")

  spec.add_development_dependency("rake", "~> 13.0")
end
