# frozen_string_literal: true

require_relative "lib/rails_code_auditor/version"

Gem::Specification.new do |spec|
  spec.name = "rails_code_auditor"
  spec.version = RailsCodeAuditor::VERSION
  spec.authors = ["sivamanikandan"]
  spec.email = ["sivamanikandan@railsfactory.org"]

  spec.summary = "Easily generate consolidated security and code quality reports for Ruby on Rails applications with a single command."
  spec.description = "rails_code_auditor is a developer-friendly Ruby gem that automates the process of auditing your Rails codebase. It runs a suite of essential tools—including Brakeman, Bundler Audit, RuboCop, Rails Best Practices, Flay, Flog, and License Finder—and consolidates all outputs into a single readable report."
  spec.homepage = "https://github.com/railsfactory-sivamanikandan/rails_code_auditor"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/railsfactory-sivamanikandan/rails_code_auditor"
  spec.metadata["changelog_uri"] = "https://github.com/railsfactory-sivamanikandan/rails_code_auditor/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
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
  spec.files = [
    "lib/rails_code_auditor.rb",
    "lib/rails_code_auditor/analyzer.rb",
    "lib/rails_code_auditor/report_generator.rb",
    "lib/rails_code_auditor/pdf_generator.rb",
    "lib/rails_code_auditor/grapher.rb",
    "lib/rails_code_auditor/scorer.rb",
    "lib/rails_code_auditor/llm_client.rb",
    "lib/rails_code_auditor/simplecov_runner.rb",
    "lib/rails_code_auditor/html_to_pdf_converter.rb"
  ]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_runtime_dependency "brakeman", "~> 6.0"
  spec.add_runtime_dependency "bundler-audit", "~> 0.9"
  spec.add_runtime_dependency "flay", "~> 2.13.3"
  spec.add_runtime_dependency "flog", "~> 4.8"
  spec.add_runtime_dependency "gruff", "~> 0.21"
  spec.add_runtime_dependency "license_finder", "~> 7.0"
  spec.add_runtime_dependency "prawn", "~> 2.4"
  spec.add_runtime_dependency "prawn-table", "~> 0.2.2"
  spec.add_runtime_dependency "rails_best_practices", "~> 1.22"
  spec.add_runtime_dependency "rubocop", "~> 1.60"
  spec.add_runtime_dependency "rubycritic", "~> 4.9.2"
  spec.add_runtime_dependency "simplecov", "~> 0.22"
  spec.add_runtime_dependency "grover"
  spec.add_runtime_dependency "combine_pdf"
  spec.add_runtime_dependency "fasterer", "~> 0.7"
  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
