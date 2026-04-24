Rollbar.configure do |config|
  # Without configuration, Rollbar is enabled in all environments.
  # To disable in specific environments, set config.enabled=false.

  config.access_token = '8840863fd42442b4be1de98bfa8baa87'

  # Here we'll disable in 'test':
  if Rails.env.test? || Rails.env.development?
    config.enabled = false
  end

  # Ensure errors in vhl gems have their stacktraces expanded.
  # See https://rollbar.com/docs/notifier/rollbar-gem/#counting-specific-gems-as-in-project-code
  config.project_gems = %w(
    avatar_service
    dangerfield
    diller
    enrollment_engine
    gradebook_engine
    hedberg
    hicks
    maestro_activity_engine
    maestro_client
    maestro_core
    music
    radner
    submission_client
    vhl-stats
    wkhtmltopdf
  )

  # By default, Rollbar will try to call the `current_user` controller method
  # to fetch the logged-in user object, and then call that object's `id`,
  # `username`, and `email` methods to fetch those properties. To customize:
  # config.person_method = "my_current_user"
  config.person_id_method = 'guid'
  # config.person_username_method = "my_username"
  # config.person_email_method = "my_email"

  # If you want to attach custom data to all exception and message reports,
  # provide a lambda like the following. It should return a hash.
  # config.custom_data_method = lambda { {:some_key => "some_value" } }

  # Add exception class names to the exception_level_filters hash to
  # change the level that exception is reported at. Note that if an exception
  # has already been reported and logged the level will need to be changed
  # via the rollbar interface.
  # Valid levels: 'critical', 'error', 'warning', 'info', 'debug', 'ignore'
  # 'ignore' will cause the exception to not be reported at all.
  # config.exception_level_filters.merge!('MyCriticalException' => 'critical')
  #
  # You can also specify a callable, which will be called with the exception instance.
  # config.exception_level_filters.merge!('MyCriticalException' => lambda { |e| 'critical' })

  # Errors to filter
  flash_reading_xml_files = /flash_reading.*\.xml"$/
  flash_reading_asset_lists = /flash_reading.*asset_?list.txt"$/
  flash_reading_swf_files = %r{/flash_reading/.*/data/swf/.*\.swf"$}
  flash_reading_redirects = /flash_reading.*_redirect.txt"$/
  mmp_play_buttons = %r{/assets/maestro_activity_engine/MMP/hd/assets/play_.*.png"$}

  routing_errors_to_ignore = Regexp.union(flash_reading_xml_files,
                                          flash_reading_asset_lists,
                                          flash_reading_swf_files,
                                          flash_reading_redirects,
                                          mmp_play_buttons)

  config.exception_level_filters.merge!('ActionController::RoutingError' => lambda do |error|
    error.to_s =~ routing_errors_to_ignore ? 'ignore' : 'warning'
  end)

  def extract_referer(request)
    headers = request[:headers] || {}
    headers['Referer']
  end

  # Ignore requests with null referers (people typing in URLs directly)
  # or that originate from domains outside our control.
  non_vhl_referer_ignorer = proc do |options|
    if options[:exception].is_a?(ActionController::RoutingError)
      referer = extract_referer(options[:scope][:request])
      vhl_host_regexp = %r{^https?://[^/]*(vistahigherlearning|vhlcentral)\.com/}
      raise Rollbar::Ignore unless referer.to_s =~ vhl_host_regexp
    end
  end
  config.before_process << non_vhl_referer_ignorer

  jwplayer_swf_ignorer = proc do |options|
    if options[:exception].is_a?(ActionController::RoutingError)
      referer = extract_referer(options[:scope][:request])
      raise Rollbar::Ignore if referer.to_s =~ %r{/players/jwplayer\.flash\.swf}
    end
  end
  config.before_process << jwplayer_swf_ignorer


  # Enable asynchronous reporting (uses girl_friday or Threading if girl_friday
  # is not installed)
  # config.use_async = true
  # Supply your own async handler:
  # config.async_handler = Proc.new { |payload|
  #  Thread.new { Rollbar.process_from_async_handler(payload) }
  # }

  # Enable asynchronous reporting (using sucker_punch)
  # config.use_sucker_punch

  # Enable delayed reporting (using Sidekiq)
  # config.use_sidekiq
  # You can supply custom Sidekiq options:
  # config.use_sidekiq 'queue' => 'default'

  # If you run your staging application instance in production environment then
  # you'll want to override the environment reported by `Rails.env` with an
  # environment variable like this: `ROLLBAR_ENV=staging`. This is a recommended
  # setup for Heroku. See:
  # https://devcenter.heroku.com/articles/deploying-to-a-custom-rails-environment
  config.environment = ENV['ROLLBAR_ENV'] || Rails.env
end
