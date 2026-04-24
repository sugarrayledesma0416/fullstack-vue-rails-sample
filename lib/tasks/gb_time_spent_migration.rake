namespace :gradebook_v2 do
  # Migrate current score actions for all sections in open courses.
  desc 'migrate time spent data to separate table'
  task migrate_time_spent: :environment do |task|
    unless ENV['BATCH_SIZE'] && ENV['SECONDS_BETWEEN_BATCHES']
      puts "USAGE: rake #{task} " \
           'BATCH_SIZE=<number of records to queue into one job> ' \
           'SECONDS_BETWEEN_BATCHES=<number of seconds to sleep after enqueuing each batch>'
      exit
    end

    start_time = Time.now

    ATTEMPT_DURATIONS_JOIN = <<~SQL.freeze
      left outer join attempt_durations ad on
        ad.user_id = current_score_actions.user_id
        and ad.section_id = current_score_actions.section_id
        and ad.activity_id = current_score_actions.activity_id
    SQL

    relation = GradebookEngine::CurrentScoreAction
               .joins(ATTEMPT_DURATIONS_JOIN)
               .where("(summation->>'time_spent') is not null")
               .where('ad.id is null')

    total_count = relation.count
    done_count = 0
    batch_size = ENV['BATCH_SIZE'].to_i
    seconds_delay = ENV['SECONDS_BETWEEN_BATCHES'].to_f
    relation.find_in_batches(batch_size) do |group|
      csa_ids = group.pluck('current_score_actions.id')

      GbMigrateTimeSpentWorker.perform_async(csa_ids)
      done_count += batch_size

      if done_count < total_count
        puts "Going to sleep for #{seconds_delay} seconds:"
        puts 'Z' + 'z' * 79
        sleep(seconds_delay)
        puts 'Awaking from sleep:'
        puts

        elapsed_time = Time.now - start_time
        elapsed_time_in_minutes = (elapsed_time / 60.0).round(2)
        done_ratio = (done_count.to_f / total_count).round(2)
        expected_total_time = (
          elapsed_time + (
            (total_count - done_count) * seconds_delay / batch_size
          )
        )
        expected_total_time_in_minutes = (expected_total_time / 60.0).round(2)
        expected_end_time = (start_time + expected_total_time).strftime('%m-%d-%Y %I:%M%p')

        puts "#{done_count} migrated out of #{total_count} total (#{done_ratio * 100}%)."
        puts "#{total_count - done_count} remaining."
        puts
        puts "Start time was #{start_time}."
        puts "Elapsed time is #{elapsed_time_in_minutes} minutes."
        puts "The task is expected to take #{expected_total_time_in_minutes} " \
             "minutes, finishing at #{expected_end_time}."
        puts

      else
        elapsed_time_in_minutes = ((Time.now - start_time) / 60.0).round(2)
        puts "Task is done: #{done_count} sections were migrated over a " \
             "period of #{elapsed_time_in_minutes} minutes, ending at " \
             "#{Time.now.strftime('%m-%d-%Y %I:%M%p')}."
      end
    end
  end
end
