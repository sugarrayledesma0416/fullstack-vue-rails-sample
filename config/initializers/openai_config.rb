VHL::AI::Core::Client.configure do |config|
  config.openai_access_token = Rails.application.config.openai_api_key
end
