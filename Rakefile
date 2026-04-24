# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

# This line prevents any Dangerfilized models
# referred in rake tasks from publishing and reacting to any callbacks,
# as well as from any networking request attempts.
Dangerfield::Gatekeeper.instance.disabled = true

Rails.application.load_tasks
