module RailsCodeAuditor
  class ReportGenerator
    def self.normalize(results)
      {
        brakeman: summarize_brakeman(results[:brakeman][:json]),
        bundler_audit: summarize_bundler(results[:bundler_audit][:json]),
        rubocop: summarize_rubocop(results[:rubocop][:json]),
        rails_best_practices: summarize_rails_best_practices(results[:rails_best_practices][:json]),
        flay: summarize_text_tool("Flay", results[:flay][:text]),
        flog: summarize_text_tool("Flog", results[:flog][:text]),
        license_finder: summarize_license_finder(results[:license_finder][:json]),
        reek: summarize_reek(results[:reek][:json]),
        rubycritic: summarize_rubycritic(results[:rubycritic][:json]),
        fasterer: summarize_fasterer(results[:fasterer][:text]),
      }
    end

    def self.summarize_brakeman(raw)
      json = JSON.parse(raw) rescue {}
      warnings = json["warnings"] || []
      summary = warnings.map { |w| "#{w['warning_type']}: #{w['message']} in #{w['file']}" }.join("\n")
      {
        status: "#{warnings.size} security warning#{'s' unless warnings.size == 1}",
        details: summary
      }
    end

    def self.summarize_bundler(raw)
      json = JSON.parse(raw) rescue {}
      vulns = json["advisories"] || []
      details = vulns.map { |v| "#{v['gem']}: #{v['title']}" }.join("\n")
      {
        status: "#{vulns.size} vulnerability#{'ies' unless vulns.size == 1}",
        details: details
      }
    end

    def self.summarize_rubocop(raw)
      json = JSON.parse(raw) rescue {}
      offenses = json["files"]&.flat_map { |f| f["offenses"] } || []
      details = offenses.map { |o| "#{o['cop_name']}: #{o['message']}" }.join("\n")
      {
        status: "#{offenses.size} code offense#{'s' unless offenses.size == 1}",
        details: details
      }
    end

    def self.summarize_rails_best_practices(raw)
      issues = JSON.parse(raw) rescue []

      status = "#{issues.size} issue#{'s' unless issues.size == 1}"
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
      lines = raw.split("\n").reject(&:empty?)
      {
        status: "#{lines.size} issue#{'s' unless lines.size == 1}",
        details: lines.first(10).join("\n") + (lines.size > 10 ? "\n..." : "")
      }
    end

    def self.summarize_license_finder(raw)
      json = JSON.parse(raw) rescue []
      problematic = json.select { |pkg| pkg["approved"] == false }
      details = problematic.map { |p| "#{p['name']} - #{p['licenses'].join(', ')}" }.join("\n")
      {
        status: "#{problematic.size} unapproved license#{'s' unless problematic.size == 1}",
        details: details
      }
    end

    def self.summarize_reek(raw)
      parsed = raw.is_a?(String) ? JSON.parse(raw, symbolize_names: true) : raw

      unless parsed.is_a?(Array)
        puts "JSON array but got #{parsed.class}"
      end

      total_smells = parsed.size
      sample_smells = parsed.first(10)

      details = sample_smells.map do |smell|
        "#{smell['source']} [#{smell['lines'].join(', ')}]: #{smell['message']} (#{smell['smell_type']})"
      end

      {
        status: "#{total_smells} smell#{'s' unless total_smells == 1}",
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
      suggestions = raw.lines.select { |line| line.include?(':') }
      {
        status: "#{suggestions.size} performance suggestion#{'s' unless suggestions.size == 1}",
        details: suggestions.join("\n")
      }
    end
  end
end