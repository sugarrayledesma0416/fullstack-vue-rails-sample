raw_yaml = Rails.root.join('config', 'assessments_config.yml').read
ASSESSMENTS_CONFIG = YAML.safe_load(raw_yaml, aliases: true)
