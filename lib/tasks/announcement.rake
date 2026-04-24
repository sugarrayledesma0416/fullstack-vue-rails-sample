require_relative 'announcement_section_generator'

namespace :run_once do
  namespace :announcements do
    desc 'create announcement sections'
    task :create_announcement_sections => :environment do
      AnnouncementSectionGenerator.generate
    end
  end
end
