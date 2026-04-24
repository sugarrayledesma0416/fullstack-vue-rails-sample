Rails.configuration.to_prepare do
  Dir[File.join(Rails.root, 'app', 'lib', 'patches', '**', '*.rb')].sort.each do |patch|
    Rails.logger.debug("Loading #{patch}...")
    require(patch)
  end
end
