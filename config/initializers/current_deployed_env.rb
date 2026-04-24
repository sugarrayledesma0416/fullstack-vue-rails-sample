# current_deployed_env_name is a uniq env name for any deployment across ua
# and m3 e.g development, live, test.
# In qa, the env name includes the qa server number, to ensure cookies
# from different qa servers don't conflict.
# ua_session_key is used in the session store initializer, so this
# initializer must get executed before that one.

name = if Rails.env == 'qa'
         `hostname`.chomp.split('.').first
       else
         Rails.env
       end

Rails.configuration.current_deployed_env_name = name
Rails.configuration.m3_session_key = "#{name}_m3_session"
Rails.configuration.fall_back_user_key = "#{name}_fall_back_user_id"
Rails.configuration.fall_back_user_guid_key = "#{name}_fall_back_user_guid"
Rails.configuration.m3_user_credentials_key = "#{name}_m3_user_credentials"

TTL_DAYS = 7
TTL_UPDATE_HOURS = 24

# default is 7 days
# you can override the default in the environment-specifc specific config files
Rails.configuration.m3_session = Struct.new(:ttl, :ttl_update_interval).new(TTL_DAYS, TTL_UPDATE_HOURS)
