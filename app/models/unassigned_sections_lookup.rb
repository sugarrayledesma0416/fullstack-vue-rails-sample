module UnassignedSectionsLookup
  private def sections
    raise "#{self.class} must implement 'sections'"
  end

  private def activity_assignments(activity_id)
    raise "#{self.class} must implement 'activity_assignments'"
  end

  def unassigned_sections(activity_id)
    section_ids = sections.collect(&:id)
    assigned_section_ids = activity_assignments(activity_id).map(&:section_id).uniq
    unassigned_section_ids = section_ids - assigned_section_ids
    sections.select { |section| unassigned_section_ids.include?(section.id) }
  end
end
