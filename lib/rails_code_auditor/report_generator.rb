module RailsCodeAuditor
  class ReportGenerator
    def self.normalize(results)
      {
        brakeman: summarize_or_skip(:brakeman, results) { |res| summarize_brakeman(res[:json]) },
        bundler_audit: summarize_or_skip(:bundler_audit, results) { |res| summarize_bundler(res[:json]) },
        rubocop: summarize_or_skip(:rubocop, results) { |res| summarize_rubocop(res[:json]) },
        rails_best_practices: summarize_or_skip(:rails_best_practices, results) do |res|
          summarize_rails_best_practices(res[:json])
        end,
        flay: summarize_or_skip(:flay, results) { |res| summarize_text_tool("Flay", res[:text]) },
        flog: summarize_or_skip(:flog, results) { |res| summarize_text_tool("Flog", res[:text]) },
        license_finder: summarize_or_skip(:license_finder, results) { |res| summarize_license_finder(res[:json]) },
        reek: summarize_or_skip(:reek, results) { |res| summarize_reek(res[:json]) },
        rubycritic: summarize_or_skip(:rubycritic, results) { |res| summarize_rubycritic(res[:json]) },
        fasterer: summarize_or_skip(:fasterer, results) { |res| summarize_fasterer(res[:text]) }
      }
    end

    def self.summarize_or_skip(tool, results)
      if results[tool]&.dig(:skipped)
        {
          status: "Skipped",
          details: results[tool][:reason] || "Tool not available in this environment"
        }
      elsif results[tool].nil?
        {
          status: "Not Run",
          details: "No data available for #{tool}"
        }
      else
        yield(results[tool])
      end
    end

    def self.summarize_brakeman(raw)
      json = parse_json_input(raw, label: "Brakeman")
      warnings = json["warnings"] || []
      summary = warnings.map { |w| "#{w["warning_type"]}: #{w["message"]} in #{w["file"]}" }.join("\n")
      {
        status: "#{warnings.size} security warning#{"s" unless warnings.size == 1}",
        details: summary
      }
    end

    def self.parse_json_input(input, label: "JSON")
      case input
      when String
        begin
          JSON.parse(input)
        rescue JSON::ParserError => e
          warn "❌ Failed to parse #{label} string: #{e.message}"
          {}
        end
      when Hash
        input
      else
        warn "❌ Unsupported #{label} input type: #{input.class}"
        {}
      end
    end

    def self.summarize_bundler(raw)
      json = begin
        JSON.parse(raw)
      rescue StandardError
        {}
      end
      vulns = json["advisories"] || []
      details = vulns.map { |v| "#{v["gem"]}: #{v["title"]}" }.join("\n")
      {
        status: "#{vulns.size} vulnerability#{"ies" unless vulns.size == 1}",
        details: details
      }
    end

    def self.summarize_rubocop(raw)
      json = begin
        JSON.parse(raw)
      rescue StandardError
        {}
      end
      offenses = json["files"]&.flat_map { |f| f["offenses"] } || []
      details = offenses.map { |o| "#{o["cop_name"]}: #{o["message"]}" }.join("\n")
      {
        status: "#{offenses.size} code offense#{"s" unless offenses.size == 1}",
        details: details
      }
    end

    def self.summarize_rails_best_practices(raw)
      issues = begin
        JSON.parse(raw)
      rescue StandardError
        []
      end

      status = "#{issues.size} issue#{"s" unless issues.size == 1}"
      grouped = issues.group_by { |issue| issue["message"] }

      details = grouped.map do |message, group|
        "#{message} (#{group.size}x)"
      end.join("\n")

      {
        status: status,
        details: details
      }
    end

    def self.summarize_text_tool(name, raw)
      lines = raw ? raw.split("\n").reject(&:empty?) : []
      {
        status: "#{lines.size} issue#{"s" unless lines.size == 1}",
        details: lines.first(10).join("\n") + (lines.size > 10 ? "\n..." : "")
      }
    end

    def self.summarize_license_finder(raw)
      json = begin
        JSON.parse(raw)
      rescue StandardError
        []
      end
      problematic = json.select { |pkg| pkg["approved"] == false }
      details = problematic.map { |p| "#{p["name"]} - #{p["licenses"].join(", ")}" }.join("\n")
      {
        status: "#{problematic.size} unapproved license#{"s" unless problematic.size == 1}",
        details: details
      }
    end

    def self.summarize_reek(raw)
      parsed = raw.is_a?(String) ? JSON.parse(raw, symbolize_names: true) : raw

      puts "JSON array but got #{parsed.class}" unless parsed.is_a?(Array)

      total_smells = parsed.size
      sample_smells = parsed.first(10)

      details = sample_smells.map do |smell|
        "#{smell["source"]} [#{smell["lines"].join(", ")}]: #{smell["message"]} (#{smell["smell_type"]})"
      end

      {
        status: "#{total_smells} smell#{"s" unless total_smells == 1}",
        details: details.join("\n") + (total_smells > 10 ? "\n..." : "")
      }
    end

    def self.summarize_rubycritic(raw)
      lines = raw.to_s.split("\n").map(&:strip).reject(&:empty?)

      # Extract score
      score_line = lines.find { |line| line.match?(/^Score:\s+\d+(\.\d+)?$/) }
      score = score_line&.match(/Score:\s+([\d.]+)/)&.captures&.first

      # Extract letter-grade issues (lines that start with a grade followed by a dash)
      issues = lines.select { |line| line.match?(/^\b[FABCDE]\b\s+-\s+/) }

      {
        status: score ? "Score: #{score}" : "No score found",
        details: issues.first(10).join("\n") + (issues.size > 10 ? "\n..." : "")
      }
    end

    def self.summarize_fasterer(raw)
      suggestions = raw.lines.select { |line| line.include?(":") }
      {
        status: "#{suggestions.size} performance suggestion#{"s" unless suggestions.size == 1}",
        details: suggestions.join("\n")
      }
    end
  end
end
