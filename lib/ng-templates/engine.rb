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

        # if app.config.ng_templates.htmlcompressor
        #   require 'htmlcompressor/compressor'
        #   unless app.config.ng_templates.htmlcompressor.is_a? Hash
        #     app.config.ng_templates.htmlcompressor = {remove_intertag_spaces: true}
        #   end
        # end
        #
        # # These engines render markup as HTML
        # app.config.ng_templates.markups.each do |ext|
        #   # Processed haml/slim templates have a mime-type of text/html.
        #   # If sprockets sees a `foo.html.haml` it will process the haml
        #   # and stop, because the haml output is html. Our html engine won't get run.
        #   mimeless_engine = Class.new(Tilt[ext]) do
        #     def self.default_mime_type
        #       nil
        #     end
        #   end
        #
        #   app.assets.register_engine ".#{ext}", mimeless_engine
        # end

        app.assets.register_mime_type 'text/ng-html', extensions: ['.nghtml']
        app.assets.register_mime_type 'text/ng-haml', extensions: ['.nghaml']
        app.assets.register_transformer 'text/ng-haml', 'application/javascript', NgTemplates::HamlProcessor
        app.assets.register_transformer 'text/ng-html', 'application/javascript', NgTemplates::Processor
      end

      # Sprockets Cache Busting
      # If ART's version or settings change, expire and recompile all assets
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
