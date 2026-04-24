class AnnouncementSectionGenerator
  def self.generate
    progress_bar = ProgressBar.create(
      title: "Announcement Section Generator",
      total: Announcement.count
    )
    Announcement.find_each do |announcement|
      progress_bar.inc
      if announcement.section_id
        AnnouncementSection.create!(section_id: announcement.section_id, announcement_id: announcement.id)
      elsif course = announcement.course
        course.section_ids.map do |section_id|
          AnnouncementSection.create!(section_id: section_id, announcement_id: announcement.id)
        end
      end
    end
    progress_bar.finish
  end
end
