require "fileutils"

module RailsCodeAuditor
  class Analyzer
    REPORT_FOLDER = "report"

    def self.ruby_version
      Gem::Version.new(RUBY_VERSION)
    end

    def self.rails_version
      defined?(Rails) ? Gem::Version.new(Rails.version) : nil
    end

    def self.run_cmd(command, raw: false)
      puts "Running: #{command}"
      output = `#{command}`
      if output.empty?
        nil
      else
        begin
          raw ? output : JSON.parse(output)
        rescue StandardError
          output
        end
      end
    end

    def self.ensure_report_folder
      FileUtils.mkdir_p(REPORT_FOLDER)
    end

    def self.write_html_report(tool_name, content)
      path = File.join(REPORT_FOLDER, "#{tool_name}.html")
      File.open(path, "w") do |f|
        f.puts "<html><head><title>#{tool_name.capitalize} Report</title></head><body><pre>"
        f.puts "<h1>#{tool_name.capitalize} Report</h1>"
        f.puts content
        f.puts "</pre></body></html>"
      end
      path
    end

    def self.generate_brakeman_html
      run_cmd("brakeman -o #{REPORT_FOLDER}/brakeman.html", raw: true)
      "#{REPORT_FOLDER}/brakeman.html"
    end

    def self.generate_rails_best_practices_html
      run_cmd("rails_best_practices -f html --output-file #{REPORT_FOLDER}/rails_best_practices.html", raw: true)
      "#{REPORT_FOLDER}/rails_best_practices.html"
    end

    def self.generate_rubycritic_html
      run_cmd("rubycritic --no-browser --path #{REPORT_FOLDER}/rubycritic", raw: true)
      "#{REPORT_FOLDER}/rubycritic/overview.html"
    end

    def self.generate_reek_html
      run_cmd("reek --format html > report/reek.html", raw: true)
      "#{REPORT_FOLDER}/reek.html"
    end

    def self.run_all
      ensure_report_folder

      results = {}

      results[:brakeman] = {
        json: run_cmd("brakeman -f json --no-exit-on-error"),
        html_path: run_cmd("brakeman -o #{REPORT_FOLDER}/brakeman.html", raw: true)
      }

      results[:bundler_audit] = {
        json: run_cmd("bundle audit check --verbose"),
        html_path: write_html_report("bundler_audit", run_cmd("bundle audit check --verbose"))
      }

      results[:rubocop] = if ruby_version >= Gem::Version.new("2.7")
                            {
                              json: run_cmd("rubocop --format json"),
                              html_path: write_html_report("rubocop", run_cmd("rubocop --format simple"))
                            }
                          else
                            { skipped: true, reason: "Rubocop requires Ruby >= 2.7" }
                          end

      results[:rails_best_practices] = {
        json: run_cmd("rails_best_practices --format json"),
        html_path: run_cmd("rails_best_practices -f html --output-file #{REPORT_FOLDER}/rails_best_practices.html",
                           raw: true)
      }

      results[:flay] = {
        text: run_cmd("flay --mass 50 ."),
        html_path: write_html_report("flay", run_cmd("flay --mass 50 ."))
      }

      results[:flog] = {
        text: run_cmd("flog ."),
        html_path: write_html_report("flog", run_cmd("flog ."))
      }

      results[:license_finder] = if ruby_version >= Gem::Version.new("2.7")
                                   {
                                     json: run_cmd("license_finder --format json"),
                                     html_path: write_html_report("license_finder",
                                                                  run_cmd("license_finder --format text"))
                                   }
                                 else
                                   { skipped: true, reason: "LicenseFinder requires Ruby >= 2.7" }
                                 end

      results[:reek] = {
        json: run_cmd("reek --format json"),
        html_path: run_cmd("reek --format html > #{REPORT_FOLDER}/reek.html", raw: true)
      }

      results[:rubycritic] = if ruby_version >= Gem::Version.new("2.7")
                               {
                                 json: run_cmd("rubycritic --format json"),
                                 html_path: run_cmd("rubycritic --no-browser --path #{REPORT_FOLDER}/rubycritic",
                                                    raw: true)
                               }
                             else
                               { skipped: true, reason: "RubyCritic requires Ruby >= 2.7" }
                             end

      results[:fasterer] = {
        text: run_cmd("fasterer ."),
        html_path: write_html_report("fasterer", run_cmd("fasterer ."))
      }

      # Optional: tools only if Rails >= 5
      if rails_version && rails_version >= Gem::Version.new("5.0")
        results[:grover] = {
          html_path: write_html_report("grover", "Grover logic here (if you use it)")
        }
      end

      results
    end
  end
end
