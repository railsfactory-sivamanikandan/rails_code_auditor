require "json"
require "net/http"
require "uri"

module RailsCodeAuditor
  class LlmClient
    def self.sanitize_results(results)
      results.transform_values do |tool|
        tool.dup.tap do |entry|
          if entry.is_a?(Hash) && entry[:details].is_a?(String)
            entry[:details] = entry[:details].slice(0, 500) # Trim details to avoid LLM overload
            entry[:details].gsub!(/\e\[[\d;]*m/, '')         # Remove ANSI color codes
          end
        end
      end
    end
    def self.score_with_llm(json_results)
      sanitized = sanitize_results(json_results)
      puts "[*] Scoring with LLM (LLaMA3)..."

      prompt = <<~PROMPT
        Analyze the following Rails code audit summary and return a JSON object like:
        {
          "security": 75,
          "code_quality": 80,
          "test_coverage": 60,
          "dependencies": 90,
          "overall": 76
        }

        Only return the raw JSON, nothing else.

        Input:
        #{JSON.pretty_generate(sanitized)}
      PROMPT

      uri = URI("http://localhost:11434/api/generate")
      body = {
        model: "llama3",
        prompt: prompt,
        stream: false
      }

      response = Net::HTTP.post(uri, body.to_json, "Content-Type" => "application/json")
      response_body = JSON.parse(response.body)

      raw_output = response_body["response"].strip
      # Try to extract JSON from any surrounding text
      json_match = raw_output.match(/\{.*\}/m)

      if json_match
        parsed_scores = JSON.parse(json_match[0])
        scored_results = parsed_scores.transform_values do |score|
          remark = case score
                  when 90..100 then "Excellent"
                  when 75..89  then "Good"
                  when 60..74  then "Average"
                  else              "Needs Improvement"
                  end
          { score: score, remark: remark }
        end
        scored_results
      else
        raise "Response did not contain valid JSON"
      end
    rescue => e
      puts "[!] LLM scoring failed: #{e.message}"
      nil
    end
  end
end