require 'logger'

module Etl
  module EtlLogger
    def log_etl_info(event, record, model = '')
      return unless log_level <= Logger::INFO

      if stats_proxy_available?
        send_logstash_data(event, model, record)
      else
        Rails.logger.info "Etl Logger: #{event} #{model} #{record}"
      end
    end

    def log_etl_error(event, error, record = '', model = '')
      return unless log_level <= Logger::ERROR

      if stats_proxy_available?
        record_etl_error_logstash(event, error, model, record)
      else
        Rails.logger.error "Etl Logger: #{event} #{error} #{model}  #{record}"
      end
    end

    def stats_proxy_available?
      defined?(STATS_PROXY) && STATS_PROXY.present?
    end

    private def log_level
      Logger.const_get(Rails.configuration.etl_log_level.to_s.upcase)
    end

    # ETL event, model in process, message
    # (either the instance being process or the error message)
    def send_logstash_data(event, model, message)
      STATS_PROXY.relay(
        application: :m3,
        environment: Rails.env,
        message: message,
        model: model,
        type: 'logstash_object',
        vhl_component: 'etl',
        vhl_event_type: event
      )
    end

    # for certain failures we want to put the actual data that failed
    # into logstash but for others we either don't have it or it is redundant
    def record_etl_error_logstash(event, error, model, record)
      STATS_PROXY.relay(
        application: :m3,
        environment: Rails.env,
        message: "#{error}:#{record}",
        model: model,
        type: 'logstash_object',
        vhl_component: 'etl',
        vhl_event_type: event
      )
    end
  end
end
