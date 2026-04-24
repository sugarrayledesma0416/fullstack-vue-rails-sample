class InstitutionAdminExternalItemsPresenter
  def initialize(section_id, program_id)
    @section_id = section_id
    @program_id = program_id
    @section = GradebookEngine::Section.find(@section_id)
  end

  def section
    @section ||= GradebookEngine::Section.find(@section_id)
  end

  def lessons
    @lessons ||= GradebookEngine::Lesson.where(program_id: @program_id).sort
  end

  def categories
    @categories ||= section.course.categories.sort
  end

  def external_items_by_lesson
    section.external_assignments
      .includes(:lesson, :category, :external_activity)
      .map do |external_assignment|
        external_activity = external_assignment.external_activity

        {
          category: external_assignment.category.name,
          category_id: external_assignment.category_id,
          due_date: external_assignment.day_id,
          due_date_display: external_assignment.day_id.strftime("%-m/%-d/%Y"),
          external_activity_id: external_activity.id,
          lesson_id: external_assignment.lesson_id,
          lesson_name: external_assignment.lesson.name,
          points_possible: external_activity.points_possible,
          title: external_activity.name
        }
      end.sort_by { |h| [h[:lesson_name], h[:due_date]] }
      .group_by { |h| h[:lesson_name] }
  end
end
