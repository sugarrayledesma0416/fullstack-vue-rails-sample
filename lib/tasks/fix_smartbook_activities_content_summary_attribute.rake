namespace :activities do
  # This task finds all the smartbook activities containing the specified type of
  # question then updates their content_summary and their points_possible.
  # for example, "matching" questions that are "qColorsActivity" type in smartbooks
  # were not recognized and so do not show in the content summary and are not taken
  # into account in the points_possible.
  desc 'Fix smartbook activities to consider specified question types'
  task fix_smartbook_questions: :environment do
    if ENV['type'].blank?
      puts "usage: rake type=<question type> dry_run=true|false"
      exit(1)
    end

    type = ENV['type']
    dry_run = ENV['dry_run'] != 'false'
    activities = Activity.where(activity_type: 'smart_book').pluck(:id)
    num_activities_updated = 0

    puts 'DRY RUN mode, no activity will be updated!' if dry_run
    progress_bar = ProgressBar.create(
      title: "Updating smartbook activity questions of type: #{type}",
      total: activities.count,
      format: "%a %e Processed: %c from %C type: #{type}"
    )
    activities.each do |activity_id|
      activity = Activity.find(activity_id)
      begin
        # this forces a parsing of the activity and thus updates the content_summary
        # and the points possible to the correct values in the activities table
        if activity.content_object.content_summary.content_summary.key?(type)
          num_activities_updated += 1

          activity.save! unless dry_run
        end
      rescue MaestroActivityEngine::XMLParser::ParserException => e
        puts "Failed to parse activity #{activity.id}: #{e.message}"
      rescue MaestroActivityEngine::ContentSummaryParseFailure => e
        puts "Failed to parse content summary for activity #{activity.id}: #{e.message}"
      end
      progress_bar.increment
    end

    progress_bar.finish
    puts "Fixed #{num_activities_updated} activities."
  end
end
