module M3CookieConfig
  class << self
    def options
      security_options.merge(domain_options)
    end

    def security_options
      if test_env? || dev_env_without_ssl?
        {}
      else
        { same_site: 'None', secure: true }
      end
    end

    # The domain option was messing with capybara browsers' ability to
    # remember cookies, so we just exclude the domain config on the test environment.
    # http://www.emmanueloga.com/2011/07/26/taming-a-capybara.html
    def domain_options
      if test_env?
        {}
      else
        { domain: '.vhlcentral.com' }
      end
    end

    # If a developer is running rails without ssl, they should set
    # USE_INSECURE_COOKIES=true in the file:
    # config/initializers/local_config.rb
    def dev_env_without_ssl?
      Rails.env.development? && defined?(USE_INSECURE_COOKIES)
    end

    def test_env?
      Rails.env.test?
    end
  end
end
