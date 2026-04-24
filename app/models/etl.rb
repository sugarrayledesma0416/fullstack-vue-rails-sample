module Etl
  def notify_update
    return if Rails.env.test? && !Rails.application.config.update_test_gradebook

    # either schedule the GBDataSyncWorker sidekiq
    # job or invoke a GB API.
    params = {
      'model_name' => gradebook_class_name,
      'id' => id,
      'action' => 'add_update'
    }
    GbDataSyncWorker.perform_async(params.stringify_keys)
  end

  def notify_deletion
    return if Rails.env.test? && !Rails.application.config.update_test_gradebook

    # either schedule the GBDataSyncWorker sidekiq
    # job or invoke a GB API.
    GbDataSyncWorker.perform_async(gb_deletion_opts.stringify_keys)
  end

  # override as necessary - e.g. User
  def gradebook_class_name
    self.class.name
  end

  def update_gradebook
    if is_deleted?
      notify_deletion
    else
      notify_update
    end
  end

  # subclasses can override if the gradebook requires more than the object id
  # to identity the object for deletion - e.g. in the case of an Assignment,
  # the GB needs the section_id and activity_id, Enrollment - seciton_id and user_id
  def gb_deletion_opts
    {
      'model_name' => gradebook_class_name,
      'id' => id,
      'action' => 'delete'
    }
  end

  # subclasses will override if they have different deleted state indicators,
  # e.g. Course/Section - is_archived flag set to true
  def is_deleted?
    transaction_include_any_action?([:destroy])
  end

  class RecordDestination
    include SqsClientWriter
    def initialize(params)
      super(params)
    end

    def write(record)
      send_message(record)
    end

    # clean up anything that requires closing, etc.
    def close
    end
  end

  class ExportTransform
    def initialize(params)
      @params = params
    end

    def process(record)
      record.to_json
    end
  end
end
