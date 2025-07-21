# frozen_string_literal: true

require "spec_helper"
require "rails_code_auditor/pdf_generator"
require "combine_pdf"
require "prawn"
require "fileutils"

RSpec.describe RailsCodeAuditor::PdfGenerator do
  let(:results) do
    {
      code_quality: { status: "pass", details: "No major issues." },
      security: { status: "fail", details: "Found 2 vulnerable gems." }
    }
  end

  let(:scores) do
    {
      code_quality: { score: 85, remark: "Good" },
      security: { score: 40, remark: "Needs improvement" }
    }
  end

  let(:graphs) do
    [
      { title: "Code Complexity", path: "spec/fixtures/graph1.png" },
      { title: "Test Coverage", path: "spec/fixtures/graph2.png" }
    ]
  end

  let(:html_pdf_paths) { ["spec/fixtures/sample1.pdf", "spec/fixtures/sample2.pdf"] }

  before do
    FileUtils.mkdir_p("spec/fixtures")

    # Create valid dummy PDFs
    html_pdf_paths.each do |pdf_path|
      Prawn::Document.generate(pdf_path) { text "Dummy PDF #{pdf_path}" }
    end

    # Create minimal valid PNGs
    graphs.each do |graph|
      File.open(graph[:path], "wb") do |f|
        f.write([
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, # PNG Signature
          0x00, 0x00, 0x00, 0x0D,                         # IHDR Chunk length
          0x49, 0x48, 0x44, 0x52,                         # "IHDR"
          0x00, 0x00, 0x00, 0x01,                         # width: 1
          0x00, 0x00, 0x00, 0x01,                         # height: 1
          0x08, 0x06, 0x00, 0x00, 0x00,                   # bit depth, color type, compression, filter, interlace
          0x1F, 0x15, 0xC4, 0x89,                         # CRC
          0x00, 0x00, 0x00, 0x0A,                         # IDAT chunk length
          0x49, 0x44, 0x41, 0x54,                         # "IDAT"
          0x78, 0x9C, 0x63, 0x60, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, # compressed data + CRC
          0xE5, 0x27, 0xD4, 0xA2,
          0x00, 0x00, 0x00, 0x00,                         # IEND chunk length
          0x49, 0x45, 0x4E, 0x44,                         # "IEND"
          0xAE, 0x42, 0x60, 0x82                          # CRC
        ].pack("C*"))
      end
    end
  end

  after do
    FileUtils.rm_f("code_audit_report.pdf")
    FileUtils.rm_f("tmp/main_audit.pdf")
    FileUtils.rm_rf("tmp")
    FileUtils.rm_rf("report/pdf")
    FileUtils.rm_rf("spec/fixtures")
  end

  it "generates a main audit PDF and merges it with HTML PDFs" do
    described_class.generate(results, scores, graphs, html_pdf_paths)

    expect(File.exist?("tmp/main_audit.pdf")).to be true
    expect(File.exist?("code_audit_report.pdf")).to be true

    combined = CombinePDF.load("code_audit_report.pdf")
    expect(combined.pages.count).to be >= 1
  end

  it "handles missing HTML PDFs gracefully" do
    missing_paths = ["spec/fixtures/missing1.pdf"]
    expect do
      described_class.generate(results, scores, graphs, missing_paths)
    end.not_to raise_error

    expect(File.exist?("code_audit_report.pdf")).to be true
  end

  it "handles missing graph files gracefully" do
    broken_graphs = [
      { title: "Missing Graph", path: "spec/fixtures/does_not_exist.png" }
    ]
    expect do
      described_class.generate(results, scores, broken_graphs, [])
    end.not_to raise_error
  end
end
