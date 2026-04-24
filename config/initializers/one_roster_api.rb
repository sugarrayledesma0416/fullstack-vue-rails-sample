Rails.application.configure do
  config.ra_api_username = ENV['ROSTER_ASSISTANT_API_USERNAME'] || 'maestro'
  config.ra_api_password = ENV['ROSTER_ASSISTANT_API_PASSWORD'] || 'password'
end
