module Portfolio
  class UpdateGroupWorker
    include Sidekiq::Worker
    include Portfolio::SyncService
    include WorkerInstrumentation

    sidekiq_options queue: :medium_priority, retry: 3, failures: :exhausted

    sidekiq_retry_in do |count|
      [8, 13, 21, 34][count]
    end

    sidekiq_retries_exhausted do |msg|
      Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
    end

    def perform(section_id)
      initialize_data(section_id)
      group_update_required? &&
        update_group_details(@school_config, @section, @group_details['id'])

      missing_group_admins? && update_group_members(
        @school_config,
        @section.guid,
        @added_users,
        @removed_users,
        'admin'
      )
    end

    private def initialize_data(section_id)
      logger_data_merge(section_id:)
      @section = Section.find(section_id)
      @school_config = @section.school.school_config
      @group_details = get_group_by_id(@school_config, @section.guid)[0]
    end

    private def group_update_required?
      @group_details['name'] != @section.name ||
      @section.additional_info != @group_details['description']
    end

    private def missing_group_admins?
      section_usernames = @section.instructors.pluck('username')
      group_members = @group_details['members']
                      .select { |member| member['role'] == 'admin' }
                      .pluck('username')
      @added_users = section_usernames - group_members
      @removed_users = group_members - section_usernames
      @added_users.present? || @removed_users.present?
    end
  end
end
