class CopyExternalItemsWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(destination_section_id, source_section_id, use_course_categories_map = false, categories_hash = nil)
    if use_course_categories_map && categories_hash.nil?
      raise ArgumentError, 'categories_hash must be provided when use_course_categories_map is true'
    end

    destination_section = Section.including_enterprise.find(destination_section_id)
    destination_section_ids = fetch_destination_section_ids(destination_section)

    destination_section_ids.each do |section_id|
      GradebookEngine::GradebookAPI.copy_external_assignments(
        source_section_id,
        section_id,
        use_course_categories_map ? categories_hash : nil
      )
    end

    at(100)
  end

  private def fetch_destination_section_ids(destination_section)
    if destination_section.is_enterprise?
      [destination_section.id] + Section.where(
        source_template_id: destination_section.id
      ).pluck(:id)
    else
      [destination_section.id]
    end
  end
end
