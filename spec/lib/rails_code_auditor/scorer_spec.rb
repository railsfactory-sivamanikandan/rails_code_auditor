require "spec_helper"
require "rails_code_auditor/scorer"

RSpec.describe RailsCodeAuditor::Scorer do
  describe ".score" do
    let(:results) do
      {
        brakeman: { status: "Found 3 issues" },
        bundler_audit: { status: "Found 1 issue" },
        rubocop: { status: "Found 5 issues" },
        rails_best_practices: { status: "Found 2 issues" },
        reek: { status: "Found 4 issues" },
        flay: { status: "Found 0 issues" },
        flog: { status: "Found 3 issues" },
        fasterer: { status: "Found 1 issue" },
        rubycritic: { status: "Score: 85.3" },
        license_finder: { status: "Found 1 issue" },
        simplecov: { status: "Coverage: 91.2" }
      }
    end

    it "returns a complete score hash with all categories and overall" do
      scores = described_class.score(results)

      expect(scores.keys).to contain_exactly(:security, :code_quality, :dependencies, :test_coverage, :overall)

      expect(scores[:security][:score]).to be_a(Integer)
      expect(scores[:code_quality][:score]).to be_a(Integer)
      expect(scores[:dependencies][:score]).to be_a(Integer)
      expect(scores[:test_coverage][:score]).to eq(91)
      expect(scores[:overall][:score]).to be_a(Integer)
    end
  end

  describe ".remark_for" do
    it "returns correct remarks based on score" do
      expect(described_class.remark_for(95)).to eq("Excellent")
      expect(described_class.remark_for(80)).to eq("Good")
      expect(described_class.remark_for(65)).to eq("Fair")
      expect(described_class.remark_for(40)).to eq("Needs Improvement")
    end
  end

  describe ".extract_issue_count" do
    it "extracts numeric count from status" do
      expect(described_class.extract_issue_count("Found 3 issues")).to eq(3)
    end

    it "returns nil if status is skipped" do
      expect(described_class.extract_issue_count("Skipped")).to be_nil
    end

    it "returns 0 if no number is present" do
      expect(described_class.extract_issue_count("All good")).to eq(0)
    end
  end

  describe ".extract_rubycritic_score" do
    it "parses float score correctly" do
      expect(described_class.extract_rubycritic_score("Score: 79.8")).to eq(80)
    end

    it "returns nil if rubycritic was skipped" do
      expect(described_class.extract_rubycritic_score("Skipped")).to be_nil
    end
  end

  describe ".calculate_score" do
    it "returns 100 if no issues" do
      expect(described_class.calculate_score(0, 3)).to eq(100)
    end

    it "returns 0 if no active tools" do
      expect(described_class.calculate_score(10, 0)).to eq(0)
    end

    it "calculates score correctly within 0–100 range" do
      expect(described_class.calculate_score(30, 1)).to eq(70) # Fixed expectation
      expect(described_class.calculate_score(1, 10)).to be_between(90, 100)
    end
  end

  describe ".overall_score" do
    it "averages all category scores" do
      scores = {
        security: { score: 80 },
        code_quality: { score: 70 },
        dependencies: { score: 100 },
        test_coverage: { score: 90 }
      }

      expect(described_class.overall_score(scores)).to eq(85)
    end

    it "returns 0 if no scores present" do
      expect(described_class.overall_score({})).to eq(0)
    end
  end
end
