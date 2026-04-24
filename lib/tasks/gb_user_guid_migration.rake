namespace :gradebook_v2 do
  # Migrate guids for all users in gradebook.
  desc 'migrate guids for all users in gradebook'
  task :migrate_guids => :environment do |task|
    unless ENV['USERS_PER_BATCH'] && ENV['SECONDS_BETWEEN_BATCHES'] && ENV['TOTAL_USERS']
      puts "USAGE: rake #{task} " \
           'USERS_PER_BATCH=<number of users to load at a time> ' \
           'SECONDS_BETWEEN_BATCHES=<number of seconds to sleep after processing each batch>' \
           'TOTAL_USERS=<number of users to process in this run of the task>'
      exit
    end

    def sleep_with_console_logging(seconds)
      puts "Going to sleep for #{seconds} seconds:"
      puts 'Z' + 'z'*79
      sleep(seconds.to_f)
      puts 'Awaking from sleep:'
      puts
    end

    def time_and_count_stats(start_time, done_count, total_count)
      elapsed_time = Time.now - start_time
      elapsed_time_in_minutes = (elapsed_time/60.0).round(2)
      done_ratio = (done_count.to_f / total_count).round(2)
      expected_total_time = (elapsed_time + ((total_count - done_count) * ENV['SECONDS_BETWEEN_BATCHES'].to_f / ENV['USERS_PER_BATCH'].to_i))
      expected_total_time_in_minutes = (expected_total_time / 60.0).round(2)
      expected_end_time = (start_time + expected_total_time).strftime('%m-%d-%Y %I:%M%p')

      { elapsed_time_in_minutes: elapsed_time_in_minutes,
        done_ratio: done_ratio,
        expected_total_time_in_minutes: expected_total_time_in_minutes,
        expected_end_time: expected_end_time }
    end

    def log_stats_to_console(start_time, done_count, total_count)
      stats = time_and_count_stats(start_time, done_count, total_count)

      puts %Q(
        #{done_count} migrated out of #{total_count} total (#{stats[:done_ratio] * 100}%).
        #{total_count - done_count} remaining.

        Start time was #{start_time}.
        Elapsed time is #{stats[:elapsed_time_in_minutes]} minutes.
        The task is expected to take #{stats[:expected_total_time_in_minutes]} minutes,
        finishing at #{stats[:expected_end_time]}.

      )
    end

    def log_done_to_console(start_time, done_count)
      elapsed_time_in_minutes = ((Time.now - start_time)/60.0).round(2)
      puts %Q(
        Task is done:
        #{done_count} user guids were migrated
        over a period of #{elapsed_time_in_minutes} minutes,
        ending at #{Time.now.strftime('%m-%d-%Y %I:%M%p')}.
      )
    end

    total_users = ENV['TOTAL_USERS'].to_i
    users_per_batch = ENV['USERS_PER_BATCH'].to_i
    seconds_between_batches = ENV['SECONDS_BETWEEN_BATCHES'].to_i

    start_time = Time.now

    # Get count of all gradebook users that don't have guids yet.
    # Process up to the specified TOTAL_USERS to be processed.
    total_count = [GradebookEngine::User.where('guid is null').count,
                   total_users].min
    done_count = 0

    while done_count < total_count do
      # Process specified count of USERS_PER_BATCH
      #   or remaining count, whichever is less.

      to_process_count = [users_per_batch,
                          (total_count - done_count)].min
      user_ids = GradebookEngine::User
        .where('guid is null')
        .limit(to_process_count)
        .pluck(:id)

      User.where(id: user_ids).each(&:notify_update)

      done_count += user_ids.size

      if done_count < total_count
        sleep_with_console_logging(seconds_between_batches)
        log_stats_to_console(start_time, done_count, total_count)
      else
        log_done_to_console(start_time, done_count)
      end
    end
  end
end
