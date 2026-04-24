config_file = Rails.root.join('config/zendesk.yml')

Rails.configuration.zendesk =
  if File.exist?(config_file)
    yaml = ERB.new(File.read(config_file)).result
    (YAML.safe_load(yaml, aliases: true)[Rails.env] || {}).symbolize_keys
  elsif %w[live qa staging].include?(Rails.env)
    {
      key: ENV.fetch('ZENDESK_KEY'),
    }
  else
    {}
  end
