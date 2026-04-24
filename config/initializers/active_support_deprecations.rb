# When the env var is set, deprecation warnings include a stacktrace to help
# identify whats calling the deprecated methods.
ActiveSupport::Deprecation.debug = ENV['DEBUG_DEPRECATIONS'].present?
