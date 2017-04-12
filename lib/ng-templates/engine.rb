require 'tilt'

module NgTemplates
  class Engine < ::Rails::Engine
    config.ng_templates = ActiveSupport::OrderedOptions.new
    config.ng_templates.module_name    = 'templates'
    config.ng_templates.ignore_prefix  = %w(templates/)
    config.ng_templates.inside_paths   = []
    config.ng_templates.markups        = []
    config.ng_templates.htmlcompressor = false

    config.before_configuration do |app|
      config.ng_templates.inside_paths = [Rails.root.join('app', 'assets')]

      # try loading common markups
      %w(erb haml liquid md radius slim str textile wiki).
      each do |ext|
        begin
          silence_warnings do
            config.ng_templates.markups << ext if Tilt[ext]
          end
        rescue LoadError
          # They don't have the required library required. Oh well.
        end
      end
    end


    initializer 'ng-templates', group: :all  do |app|
      if app.config.assets
        require 'sprockets'
        require 'sprockets/engines'

        Sprockets.register_mime_type 'text/ng-html', extensions: ['.nghtml']
        Sprockets.register_mime_type 'text/ng-haml', extensions: ['.nghaml']
        Sprockets.register_transformer 'text/ng-haml', 'application/javascript', NgTemplates::HamlProcessor
        Sprockets.register_transformer 'text/ng-html', 'application/javascript', NgTemplates::Processor
      end

      app.config.assets.version = [
        app.config.assets.version,
        'ART',
        Digest::MD5.hexdigest("#{VERSION}-#{app.config.ng_templates}")
      ].join '-'
    end


    config.after_initialize do |app|
      # Ensure ignore_prefix can be passed as a String or Array
      if app.config.ng_templates.ignore_prefix.is_a? String
        app.config.ng_templates.ignore_prefix = Array(app.config.ng_templates.ignore_prefix)
      end
    end
  end
end
