namespace :gradebook_v2 do
  desc 'populate migratable_sections'
  task :populate_migratable_sections => :environment do |task|
    GradebookEngine::Base.connection.execute(
      %q(
        insert into migratable_sections(section_id, course_end_date, migrated, created_at, updated_at)
        select s.id, c.end_date, false, now(), now()
        from sections s
        inner join courses c
        on s.course_id = c.id;
      )
    )
  end

  # Migrate current score actions for all sections in open courses.
  desc 'migrate current score actions for all sections in open courses'
  task :migrate_current_score_actions => :environment do |task|
    unless ENV['ENDING_AFTER'] && ENV['SECTIONS_PER_BATCH'] && ENV['SECONDS_BETWEEN_BATCHES']
      puts "USAGE: rake #{task} ENDING_AFTER=<date that course end date must exceed> " \
           'SECTIONS_PER_BATCH=<number of sections to queue in parallel> ' \
           'SECONDS_BETWEEN_BATCHES=<number of seconds to sleep after enqueuing each batch>'
      exit
    end

    start_time = Time.now

    # Find all sections for courses with end_date > ENDING_AFTER
    #   that are not migrated yet.
    all_section_ids = GradebookEngine::MigratableSection
      .where('not(migrated) and course_end_date > ?', ENV['ENDING_AFTER'])
      .map(&:section_id)
    total_count = all_section_ids.size
    done_count = 0

    # Batch these into groups of size SECTIONS_PER BATCH.
    # For each batch,
    #   for each section in the batch,
    #     enqueue a job that migrates the section
    #   sleep for SECONDS_BETWEEN_BATCHES
    all_section_ids.each_slice(ENV['SECTIONS_PER_BATCH'].to_i) do |section_ids|
      section_ids.each do |section_id|
        GbMigrateSectionCurrentScoreActionsWorker.perform_async(section_id)
        done_count += 1
      end

      if done_count < total_count
        puts "Going to sleep for #{ENV['SECONDS_BETWEEN_BATCHES']} seconds:"
        puts 'Z' + 'z'*79
        sleep(ENV['SECONDS_BETWEEN_BATCHES'].to_f)
        puts 'Awaking from sleep:'
        puts

        elapsed_time = Time.now - start_time
        elapsed_time_in_minutes = (elapsed_time/60.0).round(2)
        done_ratio = (done_count.to_f / total_count).round(2)
        expected_total_time = (elapsed_time + ((total_count - done_count) * ENV['SECONDS_BETWEEN_BATCHES'].to_f / ENV['SECTIONS_PER_BATCH'].to_i))
        expected_total_time_in_minutes = (expected_total_time / 60.0).round(2)
        expected_end_time = (start_time + expected_total_time).strftime('%m-%d-%Y %I:%M%p')

        puts "#{done_count} migrated out of #{total_count} total (#{done_ratio * 100}%)."
        puts "#{total_count - done_count} remaining."
        puts
        puts "Start time was #{start_time}."
        puts "Elapsed time is #{elapsed_time_in_minutes} minutes."
        puts "The task is expected to take #{expected_total_time_in_minutes} minutes, finishing at #{expected_end_time}."
        puts

      else
        elapsed_time_in_minutes = ((Time.now - start_time)/60.0).round(2)
        puts "Task is done: #{done_count} sections were migrated over a period of #{elapsed_time_in_minutes} minutes, ending at #{Time.now.strftime('%m-%d-%Y %I:%M%p')}."
      end
    end
  end
end
