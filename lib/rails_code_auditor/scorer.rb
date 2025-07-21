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

      overall = overall_score(scores)
      scores[:overall] = {
        score: overall,
        remark: remark_for(overall)
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
      tool_scores = [
        extract_issue_count(results.dig(:brakeman, :status)),
        extract_issue_count(results.dig(:bundler_audit, :status))
      ].compact

      total = tool_scores.sum
      active_tools = tool_scores.size
      calculate_score(total, active_tools)
    end

    def self.code_quality_score(results)
      issue_counts = [
        extract_issue_count(results.dig(:rubocop, :status)),
        extract_issue_count(results.dig(:rails_best_practices, :status)),
        extract_issue_count(results.dig(:reek, :status)),
        extract_issue_count(results.dig(:flay, :status)),
        extract_issue_count(results.dig(:flog, :status)),
        extract_issue_count(results.dig(:fasterer, :status))
      ].compact

      total_issues = issue_counts.sum
      active_tool_count = issue_counts.size
      issue_score = calculate_score(total_issues, active_tool_count)

      # Handle RubyCritic separately
      rubycritic_score = extract_rubycritic_score(results.dig(:rubycritic, :status))

      if rubycritic_score
        ((issue_score + rubycritic_score) / 2.0).round
      else
        issue_score
      end
    end

    def self.extract_rubycritic_score(status)
      return nil unless status.is_a?(String)
      return nil if status.downcase.include?("skipped") || status.downcase.include?("not run")

      return unless match = status.match(/Score:\s*([0-9.]+)/)

      match[1].to_f.round
    end

    def self.dependency_score(results)
      count = extract_issue_count(results.dig(:license_finder, :status))
      return 100 if count.nil? # Tool skipped

      calculate_score(count, 1)
    end

    def self.test_coverage_score(results)
      status = results.dig(:simplecov, :status)
      return 100 if !status.is_a?(String) || status.downcase.include?("skipped") || status.downcase.include?("not run")

      if status.match(/Coverage:\s*([\d.]+)/)
        ::Regexp.last_match(1).to_f.round
      else
        0
      end
    end

    def self.extract_issue_count(status)
      return nil unless status.is_a?(String)
      return nil if status.downcase.include?("skipped") || status.downcase.include?("not run")

      if match = status.match(/(\d+)/)
        match[1].to_i
      else
        0
      end
    end

    def self.calculate_score(issue_count, active_tool_count)
      return 100 if issue_count == 0
      return 0 if active_tool_count == 0

      score = 100 - (issue_count.to_f / (active_tool_count * 10)) * 10
      [[score.round, 0].max, 100].min
    end

    def self.overall_score(scores_hash)
      category_scores = scores_hash.values.map { |v| v[:score] }.compact
      return 0 if category_scores.empty?

      (category_scores.sum / category_scores.size.to_f).round
    end
  end
end
