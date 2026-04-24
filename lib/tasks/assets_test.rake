require 'sassc-rails'
# require 'sass/rails/railtie'

namespace :assets do
  class String
    def red;            "\e[31m#{self}\e[0m" end
    def green;          "\e[32m#{self}\e[0m" end
    def cyan;           "\e[36m#{self}\e[0m" end

    def bold;           "\e[1m#{self}\e[22m" end
    def italic;         "\e[3m#{self}\e[23m" end
    def underline;      "\e[4m#{self}\e[24m" end
  end

  class SassRailsInstrumentation
    @asset_routes = []

    class << self
      attr_accessor :asset_routes

      # Instrumentation bellow is an exact copy of _url helper code from sass-rails
      # (see sass-rails-3.2.6/lib/sass/rails/helpers.rb#L18-L27)
      # with the addition of coolect_assets_routes call
      def instrument
        [:image, :video, :audio, :javascript, :stylesheet, :font].each do |asset_class|
          Sass::Rails::Helpers.class_eval %Q{
            def #{asset_class}_url(asset)
              SassRailsInstrumentation.collect_asset_routes(resolver.#{asset_class}_path(asset.value), resolver.context.pathname.to_s)
              Sass::Script::String.new("url(" + resolver.#{asset_class}_path(asset.value) + ")")
            end
          }, __FILE__, __LINE__ - 6
        end
      end

      def collect_asset_routes(path, asset)
        @asset_routes << { resource_path: path, parent: asset }
      end
    end
  end

  desc 'Test availability for all resources listed under asset-url '\
       '(include image-url and others) in the project assets.'
  task :test_sass, [:verbose, :fail_on_404, :keep_compiled] do |_task, args|
    PARAMETERS_KEY = 'action_dispatch.request.path_parameters'.freeze
    TEMP_ASSETS_DIRECTORY = 'assets'.freeze

    SassRailsInstrumentation.instrument

    # tweak config first
    config = Rails.application.config

    # Disables the Asset cache to force recompile
    config.assets.compile = true
    config.assets.cache_store = :null_store
    config.sass.cache = false

    # also force remove sass cache if any
    FileUtils.rm_rf('tmp/cache/assets')

    Rails.application.initialize!

    # this should be set after initialization
    config.assets.compile = true

    # this needed to make Sass::Rails works
    # and it has to be included after Rails app initialization (Magic)
    include Sprockets::Helpers::RailsHelper
    include Sprockets::Helpers::IsolatedHelper

    # in case it wasn't initialized by the app for some reason
    require 'sassc/rails/railtie'

    app = Rails.application
    if app.assets
      app.assets.context_class.extend(Sass::Rails::Railtie::SassContext)
      app.assets.context_class.sass_config = app.config.sass
    end

    begin
      # store compiled assets into temp directory
      target = File.join(Rails.public_path, TEMP_ASSETS_DIRECTORY)

      Sprockets::StaticCompiler.new(Rails.application.assets,
                                    target,
                                    config.assets.precompile,
                                    digest: config.assets.digest,
                                    manifest: true).compile

      not_found_assets = []

      SassRailsInstrumentation.asset_routes.each do |asset|
        if File.exist?(File.join(Rails.public_path, asset[:resource_path]))
          puts "200 - #{asset[:resource_path]}".bold
        else
          message = "404 - #{asset[:resource_path]} refereed in #{asset[:parent]}".red.bold
          not_found_assets << message
        end
      end
    ensure
      FileUtils.rm_rf(target) unless eval(args[:keep_compiled])
    end

    not_found_assets.uniq.each do |message|
      puts message
    end

    if eval(args[:fail_on_404])
      raise "#{not_found_assets.size} unresolved assets" if not_found_assets.size > 0
    else
      puts "Number of not resolved resources (404) #{not_found_assets.uniq.size}. Totally referred #{not_found_assets.size} times.".bold
    end

    puts ''
    puts 'Total number of asset_url references in scss assets '\
         "#{SassRailsInstrumentation.asset_routes.size}".bold
  end
end
