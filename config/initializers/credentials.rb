credentials_json = ENV['HTTP_BASIC_AUTH_CREDENTIALS']
HTTP_AUTHENTICATIONS = if credentials_json && !credentials_json.empty?
                         JSON.parse(credentials_json)
                       else
                         {}
                       end

Rails.configuration.lossless_api_password = ENV['LOSSLESS_API_PASSWORD']
Rails.configuration.ua_api_password = ENV['UA_API_PASSWORD']
