namespace :activities do
  desc 'Sanitize activity instructor create activity title'
  task sanitize_instructor_created_activity_titles: :environment do |_cmd_name|
    InstructorCreatedActivity.find_in_batches(batch_size: 500) do |activities|
      activities.each do |activity|
        formatted_title = activity.title
                                  .gsub(/&lt;/i, '<')
                                  .gsub(/&gt;/i, '>')
                                  .gsub(/&amp;/i, '&')
                                  .gsub(/&#9;/i, '')
                                  .gsub(/&#10;/i, '')
                                  .gsub(/&#34;/i, '"')
                                  .gsub(/h\d|font/i, 'html')
                                  .gsub(/p\>/i, 'html>')
                                  .gsub(/(\ ?)(\w+\s+\{[^}]*\})/i, '')

        next unless activity.title != formatted_title

        sanitized_title = ActionController::Base.helpers.sanitize(formatted_title,
                                                                  tags: %w(u b i))

        activity.update!(title: sanitized_title,
                                    language_code: activity.program.language_code)
      end
    end
  end
end
