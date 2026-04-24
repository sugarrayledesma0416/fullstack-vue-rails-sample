require 'rake/sprocketstask'

# This convoluted hackery is needed because the SprocketsTask class
# defines a non-configurable log level at initializer and uses the
# with_logger method to replace any other configured log with its
# own logger.
# See the initialize and with_logger methods here:
# https://github.com/rails/sprockets/blob/v3.7.2/lib/rake/sprocketstask.rb
class QuietSprocketsTask < Sprockets::Rails::Task
  def define
    super

    namespace :assets do
      desc "Compile all the assets with log level set to WARN"
      task :quiet_precompile => :environment do
        puts 'starting quiet precompile'
        with_logger do
          logger.level = Logger::WARN
          manifest.compile(assets)
        end
        puts 'finished quiet precompile'
      end
    end

    # This is a hack to make sure that `bin/vite build` runs after
    # assets:precompile.
    #
    # The vite_ruby .rake file calls Rake::Task['assets:precompile'].enhance
    # and passes it a block that invokes vite:install_dependencies and
    # vite:build_all. This adds the block to an array of blocks to be executed
    # after assets:precompile is done.
    #
    # When `super` is called above, however, Sprockets::Rails::Task#define
    # clears the current definition of assets:precompile, including its
    # array of post-task blocks, and substitutes its own definition.
    #
    # Explicitly reloading the .rake file runs the `enhance` call again and
    # restores the Vite-build block.
    vite_ruby_gem_dir = Gem::Specification.find_by_name('vite_ruby').gem_dir
    vite_rake_tasks_path = "#{vite_ruby_gem_dir}/lib/tasks/vite.rake"
    load(vite_rake_tasks_path)
  end
end

QuietSprocketsTask.new(Rails.application)
