require 'concurrent'
require 'tasks/program_config_utils' # For copy_unpublished_configs task.
require 'tasks/support/task_validator'

namespace :run_once do
  desc 'Update partner chat attempts for instructors that were ' \
    'created with status code COMPLETED and no responses to have status code CODE_OPENED.'
  task update_pchat_attempts_for_instructors: :environment do
    thread_count = (ENV['THREADS'] || 32).to_i

    counter = Concurrent::AtomicFixnum.new(0)
    instructor_count = Instructor.count

    activity_ids = if ENV['INFOGAP'] == 'true'
                     Activity.where(activity_type: 'infogap_partner_chat').pluck(:id)
                   else
                     Activity.where(activity_type: 'partner_chat').pluck(:id)
                   end

    queue = Queue.new
    threads = thread_count.times.map do |_|
      Thread.new do
        while (instructor_id = queue.pop)
          Attempt.where(user_id: instructor_id, activity_id: activity_ids)
            .where(status_code: AttemptStatus::CODE_COMPLETED)
            .where(saved_submission_id: nil, submission_id: nil)
            .update_all(status_code: AttemptStatus::CODE_OPENED)

          counter.increment
          current = counter.value
          next unless (current % 100).zero?

          puts "#{current}/#{instructor_count} processed, " \
            "#{queue.length} queued, #{instructor_id} last instructor id"
        end
      end
    end

    # A bit faster than Instructor.select(:id).each { |instructor| queue.push(instructor.id) }
    Instructor.pluck(:id).each { |instructor_id| queue.push(instructor_id) }

    queue.close
    threads.map(&:join)
  end

  desc 'Calls save! on activities with a rubric to populate the ' \
       'denormalized attribute has_rubric'
  task set_has_rubric_flag: :environment do
    program_ids = ENV['PROGRAM_IDS'].split(',')
    types = MaestroActivityEngine::ActivityContent::Content::RUBRIC_ACTIVITY_TYPES

    Activity.joins(lesson: :unit).where(
      activities: { activity_type: types },
      units: { program_id: program_ids }
    ).where.not(
      activities: { cms_revision_id: nil }
    ).find_each(batch_size: 200) do |activity|
      activity.save! if activity.content_object.has_rubric?
    end
  end

  namespace :vhl_image_backfill do
    def activities_set
      Activity.where.not(cms_revision_id: nil)
              .where('activities.toc_location is not null' \
                     ' OR (activities.toc_location IS NULL' \
                     " AND activities.component_name = 'Unlisted')")
              .joins(lesson: [unit: [:program]])
              .where.not('programs.is_archived')
              .order(:id)
    end

    # Backfilling in a rake task instead of during the migration to avoid using
    # a cold cache on the migration server during a deploy.
    # Backfill non instructor created content only.
    desc 'save activities to backfill has_vhl_image following migration AddHasVhlImageToActivity.'
    task :worker, [:batch_size, :offset, :activities_count] do |t, args|
      exit unless args[:batch_size].to_i > 1 && args[:offset].to_i >= 0

      activities_to_process =
        activities_set.limit(args[:batch_size].to_i).offset(args[:offset].to_i)

      puts "Batch number: #{args[:offset]} of #{args[:activities_count]} activities."

      activities_to_process.each do |activity|
        begin
          activity.save!
        rescue ActiveRecord::RecordInvalid => e
          puts "Activity with ID #{activity.id} could not be saved. Error: #{e.message}"
        end
      end
    end

    # In order to not consume all the server memory, caused by memory fragmentation.
    # We are updating the records in batches on other rake task that when completed,
    # they release the memory they used.
    desc 'Initialize batch process for the has_vhl_image property activity content.'
    task scheduler: :environment do
      activities_count = activities_set.count
      batch_size = 500.0

      # Process is divided into smaller batches and executed in separate rake tasks.
      # where at the beginning and end of its process it uses a reasonable
      # amount of memory and then frees it, to give way to the next batch.
      (activities_count / batch_size).ceil.times do |iterator|
        Rake::Task['run_once:vhl_image_backfill:worker'].invoke(batch_size, iterator * batch_size, activities_count)
        Rake::Task['run_once:vhl_image_backfill:worker'].reenable
      end
    end
  end

  task clean_up_far_future_course_end_dates: :environment do
    max_end_date = (3.years.from_now - 1.day).to_date
    Course.where(['end_date > ?', max_end_date]).each do |course|
      course.assignments.where(['due_date > ?', max_end_date]).each do |assignment|
        assignment.update!(due_date: max_end_date)
      end
      course.update!(end_date: max_end_date)
    end
  end

  namespace :icon_backfill do
    def activities_set_for_icon_field
      Activity.where(activity_type: ['dialogue_listen_and_repeat',
                                     'interactive_video',
                                     'speech_rec_listen_repeat',
                                     'vocabulary_tutorial',
                                     'vocabulary_tutorial_v2'])
        .where('activities.toc_location is not null' \
               ' OR (activities.toc_location IS NULL' \
               " AND activities.component_name = 'Unlisted')")
        .joins(lesson: [unit: [:program]])
        .where.not('programs.is_archived')
        .where("programs.family = ''" \
               ' OR programs.family IS NULL' \
               " OR programs.family = 'vista_online_learning'")
        .where('programs.maestro_version = 3')
        .order(:id)
    end

    # Backfilling in a rake task instead of during the migration to avoid using
    # a cold cache on the migration server during a deploy.
    desc 'Update activities to backfill icon for a set of activities that have speech rec.'
    task :worker, [:batch_size, :offset, :activities_count] do |t, args|
      exit unless args[:batch_size].to_i > 1 && args[:offset].to_i >= 0

      SPEECH_REC = /speech_rec/
      activities_to_process =
        activities_set_for_icon_field.limit(args[:batch_size].to_i).offset(args[:offset].to_i)

      puts "Batch number: #{args[:offset]} of #{args[:activities_count]} activities."

      activities_to_process.each do |activity|
        begin
          next if activity.icon =~ SPEECH_REC || !activity.content_object.has_speech_rec_content?

          if activity.icon.present?
            new_icon = "#{activity.icon},speech_rec"
          else
            new_icon = 'speech_rec'
          end

          activity.update!(icon: new_icon)
        rescue StandardError => e
          puts "Activity with ID #{activity.id} could not be updated. Error: #{e.message}"
        end
      end
    end

    # In order to not consume all the server memory, caused by memory fragmentation.
    # We are updating the records in batches on other rake task that when completed,
    # they release the memory they used.
    desc 'Initialize batch process for the icon property activity content.'
    task scheduler: :environment do
      activities_count = activities_set_for_icon_field.count
      batch_size = 500.0

      # Process is divided into smaller batches and executed in separate rake tasks.
      # where at the beginning and end of its process it uses a reasonable
      # amount of memory and then frees it, to give way to the next batch.
      (activities_count / batch_size).ceil.times do |iterator|
        Rake::Task['run_once:icon_backfill:worker'].invoke(batch_size, iterator * batch_size, activities_count)
        Rake::Task['run_once:icon_backfill:worker'].reenable
      end
    end
  end

  namespace :program_config do
    desc "Copy unpublished program configuration records to sync them to UA"
    task copy_unpublished_configs: :environment do |task_name|

      required_args = %w[manager_username]
      validator = Support::TaskValidator.new(task_name:, required_args:)
      validator.check_usage

      # Allow copied program configs to sync to UA.
      Dangerfield::Gatekeeper.shall_pass do
        UnpublishedProgramConfigCopier
          .new(manager_username: ENV['manager_username'], dry_run: validator.dry_run?)
          .copy_unpublished_configs
      end
    end

    # Generates GUIDs for program configurations.
    class UnpublishedProgramConfigCopier
      include ::PrintDecorator
      include ::ProgramConfigUtils

      attr_reader :manager, :manager_username, :dry_run

      def initialize(manager_username:, dry_run:)
        @manager_username = manager_username
        @dry_run = dry_run
      end

      def copy_unpublished_configs
        counts = { copied: 0, unpublished: 0, total: 0 }
        failed_program_ids = []
        programs.each do |program|
          program_config = ProgramConfig.currently_active(program)

          next unless program_config.present?
          counts[:total] += 1

          # Before adding sync to UA, the M3 configs had no GUID attribute.
          # Anything with a GUID specified is already synced.
          next unless program_config.guid.nil?
          counts[:unpublished] += 1

          # Do not copy/save if in dry run mode.
          next if dry_run

          # Create a copy of the current config. It will not save or sync
          # because we are not changing the datastore, which fails validation.
          new_config = copy(program_config:, manager_username:)

          # Assign a GUID since creation and save via rake task won't do that.
          new_config[:guid] = SecureRandom.uuid

          # Bypass validation to save the copy without changing the datastore.
          new_config.save(validate: false)

          if new_config.persisted?
            counts[:copied] += 1
          else
            failed_program_ids << program.id
          end
        end

        print_summary(counts)
        print_failed_programs(failed_program_ids)
      end

      def print_summary(counts)
        prefix = dry_run ? 'DRY RUN' : 'EXECUTED'
        color = dry_run ? 'yellow' : 'green'

        msg = prefix + ' STATUS: ' + summary(counts)
        print_message(msg, 'H1', 0, color)
      end

      private def print_failed_programs(program_ids)
        return if program_ids.empty?

        msg = "Failed to copy config for programs: #{program_ids}"
        print_message(msg, 'H1', 0, 'red')
      end

      # Required by ProgramConfigUtils#program_configs
      private def programs
        @programs ||= Program.where(is_archived: false)
      end

      private def summary(counts)
        "Copied #{counts[:copied]} of #{counts[:unpublished]} unpublished " \
        "configs (#{counts[:total]} total) for #{programs.count} programs."
      end
    end
  end
end
