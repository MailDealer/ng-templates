require 'ng-templates/compact_javascript_escape'
require 'haml'

module NgTemplates
  class HamlProcessor < Processor
    include CompactJavaScriptEscape

    def render_html(input)
      template = input[:data]
      haml_engine = Haml::Engine.new(template)
      templates_lookup = Rails.root.join('app', 'views')
      output = haml_engine.render(ActionView::Base.with_view_paths(templates_lookup))
      escape_javascript output
    rescue Haml::SyntaxError => ex
      raise Haml::SyntaxError.new("#{input[:filename]} #{ex.message}", ex.line)
    end
  end
end
