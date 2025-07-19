require "gruff"
require 'active_support/core_ext/hash/indifferent_access'

module RailsCodeAuditor
  class Grapher
    REPORT_PATH = "./report".freeze

    def self.generate(results)
      results = results.with_indifferent_access
      Dir.mkdir(REPORT_PATH) unless Dir.exist?(REPORT_PATH)

      graphs = []

      summary = {
        "Security" => results[:security],
        "Code Quality" => results[:code_quality],
        "Dependencies" => results[:dependencies],
        "Test Coverage" => results[:test_coverage],
        "Overall" => results[:overall]
      }.compact

      graphs << graph_bar("Audit Scores", summary)

      summary.each do |label, data|
        graphs << graph_pie(label, data[:score])
      end

      graphs
    end

    def self.graph_bar(title, metrics)
      g = Gruff::Bar.new
      g.title = title

      labels = {}
      metrics.each_with_index do |(label, data), index|
        score = data[:score] || 0
        labels[index] = label
        g.data(label, [score], bar_color(score))
      end

      g.labels = labels

      file_name = "#{title.downcase.gsub(" ", "_")}.png"
      path = File.join(REPORT_PATH, file_name)
      g.write(path)

      puts "Generated graph at #{path}"

      { title: title, path: path }
    end

    def self.graph_pie(title, score)
      score = score || 0
      remaining = 100 - score

      g = Gruff::Pie.new
      g.title = title
      g.data("Score", score, bar_color(score))
      g.data("Remaining", remaining, "#dddddd")

      file_name = "#{title.downcase.gsub(" ", "_")}_pie.png"
      path = File.join(REPORT_PATH, file_name)
      g.write(path)

      puts "Generated pie chart: #{path}"

      { title: title, path: path }
    end

    def self.bar_color(score)
      case score
      when 0..49   then '#e74c3c' # red
      when 50..74  then '#f1c40f' # yellow
      when 75..89  then '#3498db' # blue
      else              '#2ecc71' # green
      end
    end
  end
end