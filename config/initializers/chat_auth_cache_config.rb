raw_yaml = ERB.new(Rails.root.join('config/chat_auth_cache.yml').read).result
redis_config = (YAML.safe_load(raw_yaml, aliases: true)[Rails.env] || {}).symbolize_keys

Rails.configuration.chat_auth_cache = nil
Rails.configuration.cb_cache = nil

if redis_config && redis_config[:enabled]
  # if password key is blank, remove it so redis won't try to
  # use the blank password and cause an error
  redis_config.delete(:password) unless redis_config[:password].present?

  begin
    Rails.configuration.chat_auth_cache = Redis.new(redis_config)
  rescue StandardError => e
    VHLMonitor.notify(e)
  end

  # set up Circuitbox cache
  Rails.configuration.cb_cache = Moneta.new(:Redis, backend: Rails.configuration.chat_auth_cache)
end
