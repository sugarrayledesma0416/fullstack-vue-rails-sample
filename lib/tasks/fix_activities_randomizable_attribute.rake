namespace :activities do
  # Due to a bug, the randomizable attribute is sometimes incorrect.
  # This Rake task udpates the randomizable attribute by looking at its value
  # in the content object.
  desc 'Fix activities randomizable attribute'
  task fix_randomizable_attribute: :environment do |cmd_name|
    batch_size = ENV['batch_size']&.to_i
    seconds_between_batches = ENV['seconds_between_batches']&.to_f || 0

    if !batch_size&.positive?
      puts "Usage: #{cmd_name} batch_size=<size of the batch> " \
           '[seconds_between_batches=<number of seconds to sleep after each ' \
           'batch, Defaults to 0>]'
    else
      # The bug caused randomizable activities/assessments to be marked as
      # non randomizable. So we look for all the assessments that are
      # currently not randomizable.
      activities = if Rails.env.qa?
                     Activity.where(
                       randomizable: false
                     ).where.not(
                       component_name: 'Instructor-created Activities'
                     ).pluck(:id)
                   else
                     Activity.where(randomizable: false).pluck(:id)
                   end

      puts "Updating #{activities.count} activities using a batch size " \
        "of #{batch_size} and a sleep time of #{seconds_between_batches}s " \
        'after each batch.'

      chunks = (activities.count + batch_size - 1) / batch_size
      activities.each_slice(batch_size).with_index do |ids, index|
        Activity.where(id: ids).each do |activity|
          begin
            if activity.content_object.randomizable?
              activity.update!(randomizable: true)
            end
          rescue MaestroActivityEngine::XMLParser::ParserException => e
            puts "Failed to parse activity #{activity.id}: #{e.message}"
          end
        end
        puts "#{index + 1} of #{chunks} batches complete"
        sleep(seconds_between_batches)
      end
    end
  end
end
