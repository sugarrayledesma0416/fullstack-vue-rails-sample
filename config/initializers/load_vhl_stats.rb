yaml_filepath = Rails.root.join('config', 'vhl_stats.yml')

if File.exist?(yaml_filepath)
  settings = YAML.safe_load(yaml_filepath.read, aliases: true)[Rails.env]
end
settings ||= {}

Rails.logger.debug("VHL_STATS from yml: #{settings}")
enable = %w[development staging qa live production].include?(Rails.env)

STATS_PROXY = Diller::Proxy.new(settings, enable)
STATS_PROXY.raise_error_on_required_keys = Rails.env.development?
