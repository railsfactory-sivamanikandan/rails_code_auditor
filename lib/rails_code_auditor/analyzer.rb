module RailsCodeAuditor
  class Analyzer
    def self.run_all
      {
        brakeman: run_cmd("brakeman -f json"),
        bundler_audit: run_cmd("bundle audit check --verbose --json"),
        rubocop: run_cmd("rubocop --format json"),
        rails_best_practices: run_cmd("rails_best_practices ."),
        flay: run_cmd("flay --mass 50 ."),
        flog: run_cmd("flog ."),
        license_finder: run_cmd("license_finder --format json"),
        reek: run_cmd("reek --format json", raw: true),
        rubycritic: run_cmd("rubycritic --format json"),
      }
    end

    def self.run_cmd(command, raw: false)
      puts "Running: #{command}"
      output = `#{command}`
      return nil if output.empty?
      return output if raw

      JSON.parse(output)
    rescue JSON::ParserError
      output
    end
  end
end
