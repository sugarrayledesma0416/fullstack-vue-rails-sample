class FindLessonDiagnosticV2Activities
  extend LightService::Action

  ACTIVITIES_NOT_PRESENT = 1

  expects :lesson, :section
  promises :activities, :concepts, :assignments

  executed do |context|
    activities = Activity
                 .where(lesson_id: context.lesson, activity_type: 'diagnostic_v2')
                 .where.not(toc_location: nil)
                 .includes(study_plan_concepts: :recommendations)

    if lesson_has_summative_and_formative_activities?(activities)
      context.activities = activities
      context.concepts = concepts(context)
      context.assignments = categorize_assignments(assignments(context.section, activities))
    else
      program = context.lesson.first.program
      unit_or_lesson = program.two_tier? ? 'unit' : 'lesson'
      context.fail_and_return!(
        "This #{unit_or_lesson} does not have Practice Test activities.",
        error_code: ACTIVITIES_NOT_PRESENT
      )
    end
  end

  def self.lesson_has_summative_and_formative_activities?(activities)
    # Lesson needs to have a summative activity and at least 1 formative activity
    # in order to populate Practice Test data.
    activities.any?(&:diagnostic_v2_summative?) &&
      activities.any? { |act| !act.diagnostic_v2_summative? }
  end

  def self.assignments(section, activities)
    Assignment.where(section_id: section.id, assignable_id: activities.map(&:id))
  end

  def self.concepts(context)
    study_plan_concepts =
      context.activities.find(&:diagnostic_v2_summative?)&.study_plan_concepts ||
      StudyPlanConcept.none
    study_plan_concepts.map { |concept| concept&.diagnostic_concept }.compact.uniq.sort_by(&:ref)
  end

  def self.categorize_assignments(assignments)
    {
      formative: assignments.reject { |a| a.assignable.diagnostic_v2_summative? },
      summative: assignments.find { |a| a.assignable.diagnostic_v2_summative? }
    }
  end
end
