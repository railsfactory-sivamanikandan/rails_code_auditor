require "spec_helper"
require "rails_code_auditor/llm_client"
require "json"
require "webmock/rspec"

RSpec.describe RailsCodeAuditor::LlmClient do
  describe ".sanitize_results" do
    it "truncates details and removes ANSI codes" do
      input = {
        security: {
          details: "\e[31mThis is a long detail string with ANSI codes\e[0m" * 20
        }
      }

      result = described_class.sanitize_results(input)

      expect(result[:security][:details].length).to be <= 500
      expect(result[:security][:details]).not_to include("\e[31m")
      expect(result[:security][:details]).not_to include("\e[0m")
    end
  end

  describe ".score_with_llm" do
    let(:input) do
      {
        security: { details: "Some issue" },
        code_quality: { details: "Another issue" },
        test_coverage: { details: "Some test issue" },
        dependencies: { details: "Some dep issue" }
      }
    end

    let(:mock_response_body) do
      {
        "response" => <<~TEXT
          {
            "security": 85,
            "code_quality": 70,
            "test_coverage": 50,
            "dependencies": 90,
            "overall": 76
          }
        TEXT
      }.to_json
    end

    before do
      stub_request(:post, "http://localhost:11434/api/generate")
        .to_return(status: 200, body: mock_response_body, headers: { "Content-Type" => "application/json" })
    end

    it "returns parsed and scored results with remarks" do
      result = described_class.score_with_llm(input)
      expect(result).to include("security", "code_quality", "test_coverage", "dependencies", "overall")
      expect(result["security"]).to eq(score: 85, remark: "Good")
      expect(result["code_quality"]).to eq(score: 70, remark: "Average")
      expect(result["test_coverage"]).to eq(score: 50, remark: "Needs Improvement")
      expect(result["dependencies"]).to eq(score: 90, remark: "Excellent")
      expect(result["overall"]).to eq(score: 76, remark: "Good")
    end

    context "when the response is malformed JSON" do
      before do
        stub_request(:post, "http://localhost:11434/api/generate")
          .to_return(status: 200, body: '{"response":"not a json"}', headers: { "Content-Type" => "application/json" })
      end

      it "prints error and returns nil" do
        expect do
          result = described_class.score_with_llm({})
          expect(result).to be_nil
        end.to output(/LLM scoring failed/).to_stdout
      end
    end

    context "when the HTTP request fails" do
      before do
        stub_request(:post, "http://localhost:11434/api/generate")
          .to_raise(Errno::ECONNREFUSED)
      end

      it "rescues and returns nil with error output" do
        expect do
          result = described_class.score_with_llm({})
          expect(result).to be_nil
        end.to output(/LLM scoring failed/).to_stdout
      end
    end
  end
end
