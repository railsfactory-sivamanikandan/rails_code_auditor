require "gruff"

module RailsCodeAuditor
  class Grapher
    def self.generate(results)
      files = {}

      # Brakeman alerts count by type
      if results[:brakeman].is_a?(Hash)
        type_counts = results[:brakeman]["warnings"].group_by { |w| w["warning_type"] }.transform_values(&:count)
        files[:brakeman] = graph_pie("Brakeman Warnings", type_counts)
      end

      # RuboCop offenses by severity
      if results[:rubocop].is_a?(Hash)
        severities = results[:rubocop]["files"].flat_map { |f| f["offenses"] }.group_by { |o| o["severity"] }.transform_values(&:count)
        files[:rubocop] = graph_bar("RuboCop Offenses", severities)
      end

      files
    end

    def self.graph_pie(title, data)
      g = Gruff::Pie.new
      g.title = title
      data.each { |k, v| g.data(k, v) }
      path = "/tmp/#{title.downcase.gsub(" ", "_")}.png"
      g.write(path)
      path
    end

    def self.graph_bar(title, data)
      g = Gruff::Bar.new
      g.title = title
      data.each { |k, v| g.data(k, [v]) }
      path = "/tmp/#{title.downcase.gsub(" ", "_")}.png"
      g.write(path)
      path
    end
  end
end