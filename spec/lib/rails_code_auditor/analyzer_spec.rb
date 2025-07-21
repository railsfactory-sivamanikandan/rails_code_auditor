require "spec_helper"
require "rails_code_auditor/analyzer"

RSpec.describe RailsCodeAuditor::Analyzer do
  let(:report_folder) { RailsCodeAuditor::Analyzer::REPORT_FOLDER }

  describe ".ruby_version" do
    it "returns the current Ruby version as Gem::Version" do
      expect(described_class.ruby_version).to be_a(Gem::Version)
    end
  end

  describe ".rails_version" do
    it "returns nil if Rails is not defined" do
      hide_const("Rails")
      expect(described_class.rails_version).to be_nil
    end

    it "returns a Gem::Version if Rails is defined" do
      stub_const("Rails", double("Rails", version: "6.1.0"))
      expect(described_class.rails_version).to eq(Gem::Version.new("6.1.0"))
    end
  end

  describe ".run_cmd" do
    it "returns parsed JSON when valid JSON is returned" do
      allow(described_class).to receive(:`).and_return('{"score": 100}')
      result = described_class.run_cmd("dummy command")
      expect(result).to eq({ "score" => 100 })
    end

    it "returns raw output if JSON parsing fails" do
      allow(described_class).to receive(:`).and_return("not-json")
      result = described_class.run_cmd("invalid json")
      expect(result).to eq("not-json")
    end

    it "returns nil if output is empty" do
      allow(described_class).to receive(:`).and_return("")
      result = described_class.run_cmd("empty")
      expect(result).to be_nil
    end
  end

  describe ".ensure_report_folder" do
    it "creates the report folder" do
      FileUtils.rm_rf(report_folder)
      described_class.ensure_report_folder
      expect(Dir.exist?(report_folder)).to be true
    end
  end

  describe ".write_html_report" do
    it "creates an HTML report file with expected content" do
      described_class.ensure_report_folder
      path = described_class.write_html_report("test_tool", "Sample Report")
      expect(File.exist?(path)).to be true
      content = File.read(path)
      expect(content).to include("<h1>Test_tool Report</h1>")
      expect(content).to include("Sample Report")
    end
  end

  describe ".run_all" do
    before do
      allow(described_class).to receive(:run_cmd).and_return("dummy output")
      allow(described_class).to receive(:write_html_report).and_return("dummy_path.html")
    end

    it "returns a hash of tool results" do
      results = described_class.run_all
      expect(results).to be_a(Hash)
      expect(results.keys).to include(:brakeman, :rubocop, :fasterer)
    end

    it "includes grover if Rails >= 5.0" do
      stub_const("Rails", double("Rails", version: "6.0.0"))
      results = described_class.run_all
      expect(results.keys).to include(:grover)
    end

    it "skips grover if Rails is not present" do
      hide_const("Rails")
      results = described_class.run_all
      expect(results.keys).not_to include(:grover)
    end
  end
end
