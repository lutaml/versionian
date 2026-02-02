# frozen_string_literal: true

require_relative "lib/versionian/version"

Gem::Specification.new do |spec|
  spec.name = "versionian"
  spec.version = Versionian::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "Version scheme declaration and comparison library supporting 20+ versioning patterns"
  spec.description = "Versionian is a Ruby library for declaring, parsing, comparing, and rendering version schemes. It provides model-driven primitives for defining how versions work, supporting Semantic Versioning, Calendar Versioning, and unlimited custom schemes through YAML configuration or Ruby inheritance."
  spec.homepage = "https://github.com/lutaml/versionian"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/lutaml/versionian"
  spec.metadata["changelog_uri"] = "https://github.com/lutaml/versionian/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "singleton", "~> 0.2"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
end
