class ScheduleBulkAssignmentCreation
  extend LightService::Action

  expects :destination_section_id, :course, :assignments_hash, :categories_hash, :job_ids

  executed do |context|
    context.job_ids << schedule_bulk_assignment_creation(context)

    next context
  end

  def self.schedule_bulk_assignment_creation(context)
    BulkAssignmentWorker.perform_async(
      self.section_ids(context.destination_section_id),
      context.course.id,
      context.assignments_hash,
      context.categories_hash,
      context[:source_section_id],
      true
    )
  end

  def self.section_ids(destination_section_id)
    # If copying to an enterprise section (i.e., an enterprise course), copy to all sections in
    # the enterprise course.
    if Section.including_enterprise.find_by(id: destination_section_id.to_i)&.is_enterprise?
      [destination_section_id] + Section.where(
        source_template_id: destination_section_id
      ).pluck(:id)
    else
      [destination_section_id]
    end
  end
end
