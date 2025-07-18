module RailsCodeAuditor
  class Scorer
    def self.score(results)
      scores = {
        security: {
          score: security_score(results),
          remark: remark_for(security_score(results))
        },
        code_quality: {
          score: code_quality_score(results),
          remark: remark_for(code_quality_score(results))
        },
        dependencies: {
          score: dependency_score(results),
          remark: remark_for(dependency_score(results))
        },
        test_coverage: {
          score: test_coverage_score(results),
          remark: remark_for(test_coverage_score(results))
        }
      }

      scores
    end

    def self.remark_for(score)
      case score
      when 90..100 then "Excellent"
      when 75..89  then "Good"
      when 60..74  then "Fair"
      else              "Needs Improvement"
      end
    end

    def self.security_score(results)
      brakeman_warnings = extract_issue_count(results[:brakeman][:status])
      audit_issues = extract_issue_count(results[:bundler_audit][:status])

      total = brakeman_warnings + audit_issues
      calculate_score(total, [brakeman_warnings, audit_issues].count { |n| n > 0 })
    end

    def self.code_quality_score(results)
      rubocop_issues = extract_issue_count(results[:rubocop][:status])
      best_practice_issues = extract_issue_count(results[:rails_best_practices][:status])
      reek_issues = extract_issue_count(results[:reek][:status])
      rubycritic_issues = extract_issue_count(results[:rubycritic][:status])

      total = rubocop_issues + best_practice_issues + reek_issues + rubycritic_issues
      calculate_score(total, [rubocop_issues, best_practice_issues, reek_issues, rubycritic_issues].count { |n| n > 0 })
    end

    def self.dependency_score(results)
      license_issues = extract_issue_count(results[:license_finder][:status])
      calculate_score(license_issues, license_issues > 0 ? 1 : 0)
    end

    def self.test_coverage_score(_results)
      # You can later plug in test coverage logic here.
      # For now return 100 if not available.
      100
    end

    def self.extract_issue_count(status)
      return 0 unless status.is_a?(String)

      if match = status.match(/(\d+)/)
        match[1].to_i
      else
        0
      end
    end

    def self.calculate_score(issue_count, active_tool_count)
      return 100 if issue_count == 0
      return 0 if active_tool_count == 0

      # Simple deduction: every issue drops score a bit.
      score = 100 - (issue_count.to_f / (active_tool_count * 10)) * 10
      score = 0 if score < 0
      score = 100 if score > 100
      score.round
    end
  end
end