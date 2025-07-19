require "prawn"
require "prawn/table"
require "fileutils"
require "active_support/core_ext/string/inflections"  # <-- Add this

module RailsCodeAuditor
  class PdfGenerator
    OUTPUT_PATH = "code_audit_report.pdf"

    def self.generate(results, scores, graphs = nil)
      FileUtils.mkdir_p(File.dirname(OUTPUT_PATH))

      Prawn::Document.generate(OUTPUT_PATH) do |pdf|
        pdf.text "Rails Code Audit Report", size: 24, style: :bold, align: :center
        pdf.move_down 20

        # Summary Scores Table
        pdf.text "Audit Summary Scores", size: 16, style: :bold
        pdf.move_down 10
        summary_data = [["Metric", "Score (0-100)", "Remarks"]]
        scores.each do |metric, value|
          summary_data << [metric.to_s.humanize, value[:score], value[:remark]]
        end
        pdf.table(summary_data, header: true, width: pdf.bounds.width)
        pdf.move_down 20

        # Detailed Audit Results
        pdf.text "Detailed Audit Results", size: 16, style: :bold
        pdf.move_down 10
        results.each do |check_name, result|
          pdf.text "#{check_name.to_s.humanize}", size: 12, style: :bold
          pdf.text "Status: #{result[:status]}"
          pdf.text "Details: #{result[:details]}"
          pdf.move_down 10
        end

        # Graphs (optional)
        if graphs && !graphs.empty?
          pdf.start_new_page
          pdf.text "Visual Graphs", size: 16, style: :bold
          pdf.move_down 10

          graphs.each do |graph|
            if File.exist?(graph[:path])
              pdf.text graph[:title], size: 12, style: :bold
              pdf.image graph[:path], fit: [500, 300]
              pdf.move_down 20
            end
          end
        end

        pdf.number_pages "Page <page> of <total>", at: [pdf.bounds.right - 150, 0]
      end

      puts "[✓] PDF report saved to #{OUTPUT_PATH}"
    end
  end
end