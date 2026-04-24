require 'tasks/update_activities'

namespace :espirales do
  desc 'Update activity titles to have "Number - Title" format for each component_names'
  task update_activity_titles: :environment do |_task|
    abort if Rails.env.live?
    
    [519, 520].each do |program_id|
      program = Program.find(program_id)
      
      update_activities = UpdateActivities.new(program: program)
      update_activities.run
    end
  end
end
