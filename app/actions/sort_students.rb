class SortStudents
  extend LightService::Action

  expects :table_sort_by, :order, :section_student_scores, :concept_id

  executed do |context|
    sort_student_scores(context)
    context.section_student_scores.reverse if context.order == 'desc'
  end

  def self.sort_student_scores(context)
    return context.section_student_scores if context.table_sort_by.nil?

    concept = StudyPlanConcept.find(context.concept_id) if context.concept_id.present?

    context.section_student_scores.sort_by do |student|
      case context.table_sort_by
      when 'name'
        student.last_name
      # When sorting by summative_grade, summative or formative. If a student hasn't
      # summited the activity, his concept_score would be nil. The comparison expects a number
      # or else it will yield an error.
      when 'summative_grade'
        context.section_student_scores.summative_grade_for(student.student) || 0
      when 'summative'
        student.summative_concept_score_for(concept) || 0
      when 'formative'
        student.formative_concept_score_for(concept) || 0
      when 'change'
        student.concept_score_change(concept)
      else
        0
      end
    end
  end
end
