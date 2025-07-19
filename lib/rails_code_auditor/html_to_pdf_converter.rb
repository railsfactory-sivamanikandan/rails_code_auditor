require "fileutils"
require "grover"

module RailsCodeAuditor
  class HtmlToPdfConverter
    INPUT_PATHS = ["report", "report/rubycritic"]
    OUTPUT_PATH = "report/pdf"

    def self.puppeteer_installed?
      system("npx puppeteer --version > /dev/null 2>&1")
    end

    def self.convert_all
      unless puppeteer_installed?
        puts "[!] Puppeteer is not installed. Please run: yarn add puppeteer"
        return []
      end

      FileUtils.mkdir_p(OUTPUT_PATH)
      pdf_paths = []

      html_files = INPUT_PATHS.flat_map { |path| Dir["#{path}/*.html"] }

      if html_files.empty?
        puts "[!] No HTML files found in #{INPUT_PATHS.join(', ')}"
        return []
      end

      html_files.each do |html_path|
        begin
          relative_name = html_path.sub(%r{^.*?report/}, "").gsub("/", "_")
          pdf_filename = relative_name.sub(/\.html$/, ".pdf")
          pdf_output_path = File.join(OUTPUT_PATH, pdf_filename)

          html_content = File.read(html_path)

          grover = Grover.new(
            html_content,
            print_background: true,
            prefer_css_page_size: true,
            wait_until: 'networkidle0',
            format: 'A4',
            margin: { top: '1cm', bottom: '1cm' }
          )

          File.write(pdf_output_path, grover.to_pdf)
          pdf_paths << pdf_output_path
          puts "[✓] PDF generated: #{pdf_output_path}"

        rescue Grover::DependencyError => e
          puts "[!] Puppeteer is required but not available. Skipping: #{html_path}"
          next
        rescue => e
          puts "[!] Failed to convert #{html_path}: #{e.class} - #{e.message}"
          next
        end
      end

      pdf_paths
    end
  end
end