require_relative 'lib/lazy_api_doc/version'

Gem::Specification.new do |spec|
  spec.name          = "lazy_api_doc"
  spec.version       = LazyApiDoc::VERSION
  spec.authors       = ["Bogdan Guban"]
  spec.email         = ["biguban@gmail.com"]

  spec.summary       = "Creates openapi v3 documentation based on rspec request tests"
  spec.description   = "The gem collects all requests and responses from your request specs and generates documentationbased on it"
  spec.homepage      = "https://github.com/bguban/lazy_api_doc"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://github.com/bguban/lazy_api_doc"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
