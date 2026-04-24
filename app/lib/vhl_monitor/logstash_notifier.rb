require_relative '../vhl_monitor'

module VHLMonitor
  MONITORS = {
    mysql_server_errors: {
      ActiveRecord::ConnectionNotEstablished => [/.*/],
      ActiveRecord::StatementInvalid => [/Errno::EBADF/,
                                         /Mysql2::Error: MySQL server has gone away/]
    }
  }.freeze

  class LogstashNotifier
    def self.initialize(stuff_to_monitor)
      @exceptions = MONITORS.slice(*stuff_to_monitor).values.inject(&:merge)

      if @exceptions.nil? && !stuff_to_monitor.blank?
        message = "No monitors defined matching #{stuff_to_monitor}, "\
                   " acceptable values are #{MONITORS.keys}"

        Rails.logger.warn(message) if defined?(Rails.logger)
        VHLMonitor.notify(message)
      end
    end

    def self.notify(exception, context = '')
      require 'json'

      return if @exceptions.nil? || logstash.nil?
      (@exceptions[exception.class] || []).each do |target|
        next unless exception.respond_to?(:message) &&  exception.message =~ target

        logstash.error(message: exception.message,
                       environment: Rails.env, category: 'm3_monitoring',
                       sub_category: exception.class.name + ':' + target.to_s,
                       exception_object_id: exception.object_id,
                       backtrace: backtrace_json(exception),
                       context: context)
      end
    end

    private_class_method def self.backtrace_json(exception)
      if exception.respond_to?(:backtrace) && exception.backtrace.present?
        JSON.generate(exception.backtrace)
      else
        ''
      end
    end

    def self.logstash
      return @logstash if defined? @logstash

      @logstash = ::STATS_PROXY
    end
  end
end
