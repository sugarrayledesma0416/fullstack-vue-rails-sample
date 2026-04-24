class ScheduleExternalItemCopy
  extend LightService::Action

  expects :source_section_id, :job_ids

  executed do |context|
    context.job_ids << schedule_external_item_copy(context)

    next context
  end

  def self.schedule_external_item_copy(context)
    CopyExternalItemsWorker.perform_async(
      context.destination_section_id,
      context.source_section_id,
      _use_course_categories_map = true,
      context.categories_hash
    )
  end
end
