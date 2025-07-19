require "prawn"
require "prawn/table"
require "fileutils"
require "combine_pdf"
require "active_support/core_ext/string/inflections"

module RailsCodeAuditor
  class PdfGenerator
    OUTPUT_PATH = "code_audit_report.pdf"
    TEMP_PRWAN_PDF = "tmp/main_audit.pdf"

    def self.generate(results, scores, graphs, html_pdf_paths = [])
      FileUtils.mkdir_p("tmp")
      FileUtils.mkdir_p("report/pdf")

      # Generate main Prawn PDF
      Prawn::Document.generate(TEMP_PRWAN_PDF) do |pdf|
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
          pdf.text check_name.to_s.humanize, size: 12, style: :bold
          pdf.text "Status: #{result[:status]}"
          pdf.text "Details: #{result[:details]}"
          pdf.move_down 10
        end

        # Graphs (optional)
        if graphs && graphs.any?
          pdf.start_new_page
          pdf.text "Visual Graphs", size: 16, style: :bold
          pdf.move_down 10

          graphs.each do |graph|
            if File.exist?(graph[:path])
              pdf.text graph[:title], size: 12, style: :bold
              pdf.image graph[:path], fit: [500, 300]
              pdf.move_down 20
            else
              puts "[!] Graph file missing: #{graph[:path]}"
            end
          end
        end

        pdf.number_pages "Page <page> of <total>", at: [pdf.bounds.right - 150, 0]
      end

      puts "[✓] Main audit PDF saved to #{TEMP_PRWAN_PDF}"

      # Merge all PDFs (main + html converted)
      combined_pdf = CombinePDF.new
      combined_pdf << CombinePDF.load(TEMP_PRWAN_PDF)

      html_pdf_paths.each do |pdf_path|
        if File.exist?(pdf_path)
          puts "[+] Merging #{pdf_path}"
          combined_pdf << CombinePDF.load(pdf_path)
        else
          puts "[!] Skipped missing HTML-generated PDF: #{pdf_path}"
        end
      end

      combined_pdf.save(OUTPUT_PATH)
      puts "[✓] Final merged PDF saved to #{OUTPUT_PATH}"
    end
  end
end