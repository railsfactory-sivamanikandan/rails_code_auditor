require "spec_helper"
require "rails_code_auditor/grapher"

RSpec.describe RailsCodeAuditor::Grapher do
  let(:report_path) { RailsCodeAuditor::Grapher::REPORT_PATH }

  let(:mock_results) do
    {
      security: { score: 80 },
      code_quality: { score: 60 },
      dependencies: { score: 90 },
      test_coverage: { score: 40 },
      overall: { score: 70 }
    }
  end

  before do
    FileUtils.rm_rf(report_path) if Dir.exist?(report_path)
    allow_any_instance_of(Gruff::Base).to receive(:write).and_return(true)
  end

  describe ".generate" do
    it "creates the report directory if not present" do
      expect { described_class.generate(mock_results) }.to change { Dir.exist?(report_path) }.from(false).to(true)
    end

    it "generates bar and pie charts for each metric" do
      graphs = described_class.generate(mock_results)

      expect(graphs).to be_an(Array)
      expect(graphs.size).to eq(6) # 1 bar chart + 5 pie charts

      titles = graphs.map { |g| g[:title] }
      expect(titles).to include("Audit Scores", "Security", "Code Quality", "Dependencies", "Test Coverage", "Overall")
    end
  end

  describe ".bar_color" do
    it "returns correct color based on score ranges" do
      expect(described_class.bar_color(30)).to eq("#e74c3c")  # red
      expect(described_class.bar_color(60)).to eq("#f1c40f")  # yellow
      expect(described_class.bar_color(80)).to eq("#3498db")  # blue
      expect(described_class.bar_color(95)).to eq("#2ecc71")  # green
    end
  end

  describe ".graph_bar" do
    it "generates a bar graph and returns a hash with title and path" do
      graph = described_class.graph_bar("Test Graph", { "A" => { score: 70 } })

      expect(graph).to include(:title, :path)
      expect(graph[:title]).to eq("Test Graph")
      expect(graph[:path]).to end_with("test_graph.png")
    end
  end

  describe ".graph_pie" do
    it "generates a pie graph and returns a hash with title and path" do
      graph = described_class.graph_pie("Test Pie", 85)

      expect(graph).to include(:title, :path)
      expect(graph[:title]).to eq("Test Pie")
      expect(graph[:path]).to end_with("test_pie_pie.png")
    end
  end
end
