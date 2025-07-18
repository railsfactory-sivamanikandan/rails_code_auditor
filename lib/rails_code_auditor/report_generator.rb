module RailsCodeAuditor
  class ReportGenerator
    def self.normalize(results)
      {
        brakeman: summarize_brakeman(results[:brakeman]),
        bundler_audit: summarize_bundler(results[:bundler_audit]),
        rubocop: summarize_rubocop(results[:rubocop]),
        rails_best_practices: summarize_text_tool("Rails Best Practices", results[:rails_best_practices]),
        flay: summarize_text_tool("Flay", results[:flay]),
        flog: summarize_text_tool("Flog", results[:flog]),
        license_finder: summarize_license_finder(results[:license_finder]),
        reek: summarize_reek(results[:reek]),
        rubycritic: summarize_reek(results[:rubycritic]),
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
      raw = raw.to_json if raw.is_a?(Array)
      lines = raw.split("\n").reject(&:empty?)
      smelly_lines = lines.select { |line| line.include?('has the') || line.include?('smell') }

      {
        status: "#{smelly_lines.size} smell#{'s' unless smelly_lines.size == 1}",
        details: smelly_lines.first(10).join("\n") + (smelly_lines.size > 10 ? "\n..." : "")
      }
    end

    def self.summarize_rubycritic(raw)
      lines = raw.split("\n").reject(&:empty?)
      score_line = lines.find { |line| line.include?("Score") }

      issues = lines.select { |l| l.match?(/\b[FABCDE]\b\s+-\s+/) } # grade lines

      {
        status: score_line || "No score found",
        details: issues.first(10).join("\n") + (issues.size > 10 ? "\n..." : "")
      }
    end
  end
end