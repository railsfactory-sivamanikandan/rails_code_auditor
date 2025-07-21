require "spec_helper"
require "rails_code_auditor"

RSpec.describe RailsCodeAuditor do
  describe ".run" do
    let(:args) { [] }

    before do
      allow(RailsCodeAuditor::Analyzer).to receive(:run_all).and_return({ foo: "bar" })
      allow(RailsCodeAuditor::ReportGenerator).to receive(:normalize).and_return({ normalized: true })
      allow(RailsCodeAuditor::SimpleCovRunner).to receive(:run).and_return(coverage: 90)
      allow(RailsCodeAuditor::Scorer).to receive(:score).and_return(score: 85)
      allow(RailsCodeAuditor::Grapher).to receive(:generate).and_return("graph.png")
      allow(RailsCodeAuditor::PdfGenerator).to receive(:generate).and_return("report.pdf")
      allow(RailsCodeAuditor::HtmlToPdfConverter).to receive(:convert_all).and_return(["audit1.html", "audit2.html"])
      allow(RailsCodeAuditor::LlmClient).to receive(:score_with_llm).and_return(nil) # fallback to Scorer
    end

    it "runs the audit pipeline and prints output" do
      expect { described_class.run(args) }.to output(/Audit complete/).to_stdout

      expect(RailsCodeAuditor::Analyzer).to have_received(:run_all)
      expect(RailsCodeAuditor::ReportGenerator).to have_received(:normalize)
      expect(RailsCodeAuditor::SimpleCovRunner).to have_received(:run)
      expect(RailsCodeAuditor::Scorer).to have_received(:score)
      expect(RailsCodeAuditor::Grapher).to have_received(:generate)
      expect(RailsCodeAuditor::PdfGenerator).to have_received(:generate)
    end

    context "when --use-llm is passed" do
      let(:args) { ["--use-llm"] }

      it "uses LlmClient to score" do
        expect(RailsCodeAuditor::LlmClient).to receive(:score_with_llm)
        described_class.run(args)
      end
    end
  end
end
