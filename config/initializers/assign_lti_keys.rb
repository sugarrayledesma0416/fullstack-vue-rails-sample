raw_keys = if %w[live qa staging].include?(Rails.env)
             env_var = ENV['LTI_ADVANTAGE_KEYS']
             env_var.present? && JSON.parse(env_var).values || []
           else
             # The key checked into version control here is not a real secret.
             [File.read(File.join('config', 'lti_tool_private_key.pem'))]
           end

Rails.configuration.lti_tool_private_keys = raw_keys.map do |raw_key|
  OpenSSL::PKey::RSA.new(raw_key)
end
