RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # This avoids name collisions with the gradebook_engine factories.
  #   gradebook_engine will use it as a prefix for factory names.
  GB_FACTORY_PREFIX = 'gb_'.freeze
end

# Make gradebook_engine factory definitions available.
FactoryBot.definition_file_paths << GradebookEngine::Engine.root.join('spec', 'factories').to_s
FactoryBot.reload
