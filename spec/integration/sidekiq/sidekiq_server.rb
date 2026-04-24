# encoding: utf-8

# https://github.com/newrelic/rpm/blob/master/test/multiverse/suites/sidekiq/sidekiq_server.rb

# rails s
# load "#{Rails.root}/spec/integration/sidekiq/sidekiq_server.rb"
# SidekiqServer.instance.run

require 'sidekiq'
require 'sidekiq/cli'

class SidekiqServer
  include Singleton

  attr_reader :queue_name

  def initialize
    @queue_name = "sidekiq#{Process.pid}"
    @sidekiq = Sidekiq::CLI.instance
  end

  def run(file="sidekiq_test_worker.rb")
    @sidekiq.parse(["--require", File.join(File.dirname(__FILE__), file),
                    "--queue", "#{queue_name},1",
                    "--logfile", "log/sidekiq_server.log"])
    Thread.new { @sidekiq.run }
  end

  # If we just let the process go away, occasional timing issues cause the
  # Launcher actor in Sidekiq to throw a fuss and exit with a failed code.
  def stop
    puts "Trying to stop Sidekiq gracefully"
    @sidekiq.launcher.stop
  end
end
