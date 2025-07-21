require "json"
require "bundler"

module RailsCodeAuditor
  class SimpleCovRunner
    def self.run
      setup_file = ".simplecov_setup.rb"

      unless simplecov_installed_in_project?
        return {
          status: "Skipped",
          success: false,
          error: "simplecov gem not found in the target Rails app",
          details: "simplecov gem not found in the target Rails app"
        }
      end

      File.write(setup_file, <<~RUBY)
        require 'simplecov'

        SimpleCov.start 'rails' do
          enable_coverage :branch
          add_filter '/test/'
          add_filter '/spec/'
        end

        SimpleCov.command_name ENV.fetch("SIMPLECOV_COMMAND_NAME", "Rails Tests")
        puts "[SimpleCov] started"
      RUBY

      test_cmd =
        if Dir.exist?("spec")
          "SIMPLECOV_COMMAND_NAME='RSpec Tests' bundle exec ruby -r./#{setup_file} -S rspec"
        elsif Dir.exist?("test")
          "SIMPLECOV_COMMAND_NAME='Rails Tests' bundle exec ruby -r./#{setup_file} -S rails test"
        else
          return { status: "Coverage: 0%", error: "No test directory found", success: false,
                   details: "No test directory found" }
        end

      success = system(test_cmd)

      coverage_path = "coverage/.last_run.json"
      if File.exist?(coverage_path)
        json = JSON.parse(File.read(coverage_path))
        percent = json["result"]["covered_percent"].round(2)
        {
          status: "Coverage: #{percent}%",
          success: success,
          raw_result: json,
          details: json
        }
      else
        {
          status: "Coverage: 0%",
          success: success,
          error: "Coverage file not generated",
          details: "Coverage file not generated"
        }
      end
    ensure
      File.delete(setup_file) if setup_file && File.exist?(setup_file)
    end

    def self.simplecov_installed_in_project?
      spec = Bundler.locked_gems.specs.find { |s| s.name == "simplecov" }
      !spec.nil?
    rescue StandardError
      false
    end
  end
end
