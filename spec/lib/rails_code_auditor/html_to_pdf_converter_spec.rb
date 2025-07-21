require "spec_helper"
require "fileutils"

RSpec.describe RailsCodeAuditor::HtmlToPdfConverter do
  let(:input_dir) { "report" }
  let(:rubycritic_dir) { "report/rubycritic" }
  let(:output_dir) { "report/pdf" }
  let(:html_file) { "#{input_dir}/sample.html" }
  let(:pdf_file) { "#{output_dir}/sample.pdf" }

  before do
    # Clean up before each run
    FileUtils.rm_rf("report")
    FileUtils.mkdir_p(input_dir)
    File.write(html_file, "<html><body><h1>Hello</h1></body></html>")

    allow(described_class).to receive(:puppeteer_installed?).and_return(true)

    fake_grover = instance_double(Grover)
    allow(Grover).to receive(:new).and_return(fake_grover)
    allow(fake_grover).to receive(:to_pdf).and_return("%PDF-1.4 simulated content")
  end

  after do
    FileUtils.rm_rf("report")
  end

  describe ".convert_all" do
    it "creates PDF output from HTML files" do
      pdf_paths = described_class.convert_all

      expect(pdf_paths).to be_an(Array)
      expect(pdf_paths.first).to match(/\.pdf$/)
      expect(File).to exist(pdf_paths.first)

      content = File.read(pdf_paths.first)
      expect(content).to include("%PDF-1.4")
    end

    it "returns empty array if Puppeteer is not installed" do
      allow(described_class).to receive(:puppeteer_installed?).and_return(false)
      expect(described_class.convert_all).to eq([])
    end

    it "returns empty array if no HTML files found" do
      FileUtils.rm_f(html_file)
      expect(described_class.convert_all).to eq([])
    end
  end
end
