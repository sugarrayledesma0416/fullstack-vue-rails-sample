raw_yaml = ERB.new(Rails.root.join('config/job_conflict_cache.yml').read).result
redis_config = (YAML.safe_load(raw_yaml, aliases: true)[Rails.env] || {}).symbolize_keys

Rails.configuration.job_conflict_cache = nil

if redis_config && redis_config[:enabled]
  begin
    Rails.configuration.job_conflict_cache = Redis.new(redis_config)
  rescue StandardError => e
    VHLMonitor.notify(e)
  end
end
