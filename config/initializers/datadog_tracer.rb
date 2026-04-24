require 'm3/version'
require 'datadog/appsec'

if Rails.env.live?
  Datadog.configure do |c|
    c.version = M3::VERSION
    c.appsec.enabled = true
    c.appsec.instrument :rails

    # Enable app analytics feature
    c.tracing.analytics.enabled = true
    c.tracing.instrument :aws
    c.tracing.instrument :faraday
    # Configuring the Rack integration manually breaks AppSec
    # integration.  Datadog says this is a known issue.
    #
    # See:
    #  https://docs.google.com/document/d/1VCKucK2hOjrmF9hIZKXvhpp_MAkwspP8IAbM57q4tOc
    #
    # c.use :rack, request_queuing: true
    c.tracing.instrument :rails
    c.tracing.instrument :redis
    # Break out gradebook queries into their own service, otherwise
    # they all end up in the m3-mysql2 service.
    c.tracing.instrument :active_record, describes: :gradebook_live do |db|
      db.service_name = 'gradebook-postgres'
    end
    c.tracing.instrument :sidekiq do |sidekiq|
      sidekiq.service_name = 'sidekiq-m3'
    end
    c.tracing.log_injection = false
    c.tracing.sampler = Datadog::Tracing::Sampling::PrioritySampler.new(
      post_sampler: Datadog::Tracing::Sampling::RuleSampler.new(
        [
          Datadog::Tracing::Sampling::SimpleRule.new(
            service: 'm3',
            sample_rate: 0.25
          ),
          Datadog::Tracing::Sampling::SimpleRule.new(
            service: 'web-server',
            sample_rate: 0.15
          )
        ]
      )
    )
  end
end
