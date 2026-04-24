config_file = Rails.root.join('config/tokbox.yml')

Rails.configuration.tokbox =
  if File.exist?(config_file)
    yaml = ERB.new(File.read(config_file)).result
    (YAML.safe_load(yaml, aliases: true)[Rails.env] || {}).symbolize_keys
  else
    {}
  end
