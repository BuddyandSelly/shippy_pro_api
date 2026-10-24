# frozen_string_literal: true

require_relative "lib/shippy_pro_api/version"

Gem::Specification.new do |spec|
  spec.name = "shippy_pro_api"
  spec.version = ShippyProAPI::VERSION
  spec.authors = ["nickfarm27"]
  spec.email = ["nicholasfarm27@gmail.com"]

  spec.summary = "ShippyPro API Wrapper"
  spec.homepage = "https://github.com/PostCo/shippy_pro_api"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/PostCo/shippy_pro_api"
  spec.metadata["changelog_uri"] = "https://github.com/PostCo/shippy_pro_api/releases"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html

  spec.add_dependency "activesupport", ">= 7.0"
  # The json request and response middleware moved into faraday itself in 1.10,
  # so faraday_middleware (which never supported faraday 2) is no longer needed
  # and both faraday majors work. gemfiles/faraday1.gemfile covers the older one.
  spec.add_dependency "faraday", ">= 1.10"
  # base64 and ostruct are not default gems any more: base64 encodes the api key,
  # and ShippyProAPI::Object is an OpenStruct.
  spec.add_dependency "base64", ">= 0.2"
  spec.add_dependency "ostruct", ">= 0.6"

  spec.add_development_dependency "dotenv", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.15"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "simplecov", "~> 1.1"
  spec.add_development_dependency "webmock", "~> 3.26"
end
