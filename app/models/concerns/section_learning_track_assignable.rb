module SectionLearningTrackAssignable
  extend ActiveSupport::Concern

  def activities
    @activities ||= licensed_assignments.map do |assignment|
      next if exclude_activity?(assignment.assignable)

      {
        activity_requirements: {
          instructor_graded: assignment.assignable.instructor_graded?,
          require_microphone: assignment.assignable.chat_or_recording?,
          require_partner: assignment.assignable.partner_chat?
        },
        activity_type: assignment.assignable.activity_type,
        minutes_to_complete: assignment.assignable.minutes_to_complete,
        category: assignment.category.name,
        due_date: assignment.due_date.strftime('%m/%d/%Y'),
        group: assignment_group(assignment),
        group_id: assignment.track_group_id,
        id: assignment.assignable_id,
        individually_assignable: assignment.individually_assignable?,
        is_igc: assignment.assignable.instructor_id.present?,
        lesson_name: assignment.assignable.lesson.name,
        strand: assignment.assignable.concept.base_name.strip,
        strand_name: assignment.assignable.concept.name,
        title: assignment.assignable.title,
        unit_id: assignment.assignable.lesson.unit.id
      }
    end.compact
  end

  private def assign_chat_activities?
    @assign_chat_activities ||= course.nil? ? true : course.chat_level != 'disabled'
  end

  private def course
    @course ||= @current_course_id.nil? ? nil : Course.unscoped.find(@current_course_id)
  end

  private def exclude_activity?(activity)
    !assign_chat_activities? && activity.requires_chat?
  end

  private def assignment_group(assignment)
    assignment.track_group_name || assigned_concepts_by_id[assignment.assignable.concept_id].name
  end
end
