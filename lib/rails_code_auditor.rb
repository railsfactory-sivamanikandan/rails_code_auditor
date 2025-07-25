require "rails_code_auditor/analyzer"
require "rails_code_auditor/report_generator"
require "rails_code_auditor/pdf_generator"
require "rails_code_auditor/grapher"
require "rails_code_auditor/scorer"
require "rails_code_auditor/llm_client"
require "rails_code_auditor/simplecov_runner"

rails_version = defined?(Rails) ? Gem::Version.new(Rails::VERSION::STRING) : nil
USE_GROVER = rails_version.nil? || rails_version >= Gem::Version.new("5.0")

require "rails_code_auditor/html_to_pdf_converter" if USE_GROVER

module RailsCodeAuditor
  def self.run(args)
    puts "[*] Running Rails Code Auditor..."

    # Parse CLI options
    use_llm     = args.include?("--use-llm")
    model_arg   = args[args.index("--llm-model") + 1] if args.include?("--llm-model")
    endpoint_arg = args[args.index("--llm-endpoint") + 1] if args.include?("--llm-endpoint")

    raw_results = Analyzer.run_all
    results = ReportGenerator.normalize(raw_results)
    results[:simplecov] = SimpleCovRunner.run
    scores = if use_llm
               LlmClient.score_with_llm(results, model: model_arg || "llama3",
                                                 endpoint: endpoint_arg || "http://localhost:11434/api/generate") || Scorer.score(results)
             else
               Scorer.score(results)
             end
    graphs = Grapher.generate(scores)
    html_pdf_paths = USE_GROVER ? HtmlToPdfConverter.convert_all : []
    PdfGenerator.generate(results, scores, graphs, html_pdf_paths)
    puts "[✓] Audit complete. PDF report generated."
  end
end
