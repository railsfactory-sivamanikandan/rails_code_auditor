require "rails_code_auditor/analyzer"
require "rails_code_auditor/report_generator"
require "rails_code_auditor/pdf_generator"
require "rails_code_auditor/grapher"
require "rails_code_auditor/scorer"
require "rails_code_auditor/llm_client"
require "rails_code_auditor/simplecov_runner"
require "rails_code_auditor/html_to_pdf_converter"

module RailsCodeAuditor
  def self.run(args)
    puts "[*] Running Rails Code Auditor..."

    raw_results = Analyzer.run_all
    results = ReportGenerator.normalize(raw_results)
    results[:simplecov] = SimpleCovRunner.run
    scores = if args.include?("--use-llm")
              LlmClient.score_with_llm(results) || Scorer.score(results)
             else
              Scorer.score(results)
             end
    graphs = Grapher.generate(scores)
    html_pdf_paths = HtmlToPdfConverter.convert_all
    PdfGenerator.generate(results, scores, graphs, html_pdf_paths)
    puts "[✓] Audit complete. PDF report generated."
  end
end