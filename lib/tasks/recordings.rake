namespace :recordings do

  desc 'Create a related recording record from students responses for vchat and recording_v2 activities'
  task :create_recording_records => :environment do |task|
    start_at = ENV['start'].to_i
    batch_size = ENV['batch_size'].to_i
    unless start_at && batch_size
      puts "USAGE: rake #{task} start_at=<starting point for the batch processing> batch_size=<batch size>"
      exit
    end
    activity_ids = Activity.where("activity_type = 'recording_v2' OR activity_type = 'virtual_chat'").pluck(:id)
    hostname = defined?(CURRENT_HOST) ? CURRENT_HOST : Socket.gethostname
    log_file = File.new(Rails.root.join('log', "#{hostname}_recordings_results.log"), 'a')

    Attempt.joins('LEFT JOIN processed_attempts ON processed_attempts.attempt_id = attempts.id')
           .where(:activity_id => activity_ids).where('processed_attempts.attempt_id is null').find_in_batches(:start => start_at, :batch_size => batch_size) do |attempts|
      progress_bar = RakeProgressbar.new(attempts.size)
      attempts.each do |attempt|
        begin
          RecordingSaver.new(attempt.activity, attempt.user, attempt.results).save_recordings
          ProcessedAttempt.create!(:attempt => attempt)
          puts "Attempt id: #{attempt.id} processed correctly. Recordings created!"
        rescue Exception => e
          log_file << "\n\nError: #{attempt.inspect}  \n Backtrace: #{e.backtrace.to_yaml}"
          puts "Attempt id: #{attempt.id} was not processed correctly. Recordings were not created"
        end
        progress_bar.inc
      end

      progress_bar.finish # display a progress bar per batch?
    end
    log_file.close
  end

  desc 'Sets uuid on existing recordings and update each record'
  task :set_uuid_on_recordings => :environment do |task|
    start_at = ENV['start'].to_i
    batch_size = ENV['batch_size'].to_i
    unless start_at && batch_size
      puts "USAGE: rake #{task} start_at=<starting point for the batch processing> batch_size=<batch size>"
      exit
    end
    hostname = defined?(CURRENT_HOST) ? CURRENT_HOST : Socket.gethostname
    log_file = File.new(Rails.root.join('log', "#{hostname}_recordings_update_results.log"), 'a')
    Recording.where('uuid is null').find_in_batches(:start => start_at, :batch_size => batch_size) do |recordings|
      recordings.each do |recording|
        begin
          recording.set_uuid
          recording.save!
          puts "Recording id: #{recording.id} processed correctly!"
        rescue Exception => e
          log_file << "\n\nError: #{recording.inspect}  \n Backtrace: #{e.backtrace.to_yaml}"
          puts "Recording id: #{recording.id} was not processed correctly. Recording was not updated"
        end
      end
    end
    log_file.close
  end
end
