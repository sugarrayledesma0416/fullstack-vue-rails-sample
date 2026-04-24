module Cartridge
  class ExporterWorker
    include Sidekiq::Worker
    include WorkerInstrumentation
    include WorkerConflictManagement

    CC_IN_PROGRESS_KEY = 'CartridgeExporterWorker.%<program_id>d'.freeze

    def perform(program_id, creator_id, cc_version)
      logger_data_merge(
        program_id: program_id,
        creator_id: creator_id,
        cc_version: cc_version
      )
      cache_key = format(CC_IN_PROGRESS_KEY, program_id: program_id)
      if conflict?([cache_key])
        logger_data_merge(
          error_key: program_id,
          cc_exporter_error: 'job is currently in process for this program'
        )
      else
        in_progress(cache_key)
        exporter = Exporter.new(
          cc_version: cc_version,
          creator: User.find(creator_id),
          program: Program.find(program_id)
        )
        exporter.export
        if exporter.errors.present?
          logger_data_merge(
            error_key: program_id,
            cc_exporter_error: exporter.errors.join(',')
          )
        end
      end
    ensure
      completed_progress(cache_key)
    end
  end
end
