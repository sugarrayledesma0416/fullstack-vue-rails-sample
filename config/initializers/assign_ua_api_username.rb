Rails.configuration.ua_api_username = if Rails.env.development?
                                        'maestro'
                                      else
                                        'iron_keep_b6eef'
                                      end
