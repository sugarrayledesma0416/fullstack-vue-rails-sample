class BulkResourcesCreationTracker < ApplicationRecord
  include AASM

  aasm column: :state do
    state :pending, initial: true
    state :job_created
    state :unzipping
    state :unzipped
    state :creating_resources
    state :completed
    state :failed
    state :processing_files

    event :job_created do
      transitions from: :pending, to: :job_created
      after { log('job_created', 'The job has been created', 20) }
    end

    event :start_unzipping do
      transitions from: :job_created, to: :unzipping
      after { log('unzipping_started', 'S3 unzipping started', 40) }
    end

    event :unzipping_completed do
      transitions from: :unzipping, to: :unzipped
      after { log('unzipping_completed', 'S3 unzipping completed', 60) }
    end

    event :start_creating_resources do
      transitions from: :unzipped, to: :creating_resources
      after { log('creation_started', 'Resources creation started', 80) }
    end

    event :completed do
      transitions from: :creating_resources, to: :completed
      after { log('creation_completed', 'Resources creation completed', 100) }
    end

    event :reset do
      transitions from: %i[completed failed processing_files], to: :pending
    end

    event :fail do
      transitions from: %i[pending job_created unzipping unzipped creating_resources], to: :failed
    end

    event :processing_files do
      transitions from: %i[pending completed failed], to: :processing_files
    end
  end

  def log(key, message, progress)
    current_log = JSON.parse(logs)
    time = Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%Y-%m-%d %H:%M:%S')
    current_log['data'] << { key:, message:, time: }
    current_log['progress'] = progress
    update(logs: current_log.to_json)
  end
end
