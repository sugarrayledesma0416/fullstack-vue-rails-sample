class SessionAuditCleanerWorker
  include Sidekiq::Worker
  include WorkerInstrumentation
  include WorkerCheck

  def perform
    if no_prior_process_running?
      records = 0
      Session.expired_sessions.find_each(batch_size: 250) do |s|
        s.invalidate_ticket_and_destroy(connection)
        records += 1
      end
      logger_data_merge(expired_records: records)
    else
      logger_data_merge(
        errors: ['Aborted. Identical job running.'],
        expired_records: 0
      )
    end
  end

  # shared connection so we're not opening and closing a connection
  # for each record removed.
  private def connection
    @connection ||= ConnectionHandler.connection(
      basic_auth: [
        Rails.configuration.ua_api_username,
        Rails.configuration.ua_api_password
      ],
      request_type: :json,
      uri: URI(UA_URL)
    )
  end
end
