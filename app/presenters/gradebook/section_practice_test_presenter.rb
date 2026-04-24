class Gradebook::SectionPracticeTestPresenter < Gradebook::StudentPracticeTestPresenter
  delegate :concepts,
           :section_student_scores,
           :failure?,
           :success?,
           :section_averages,
           :summative_average, to: :results
  delegate :message, to: :results, prefix: true

  delegate :student_rows, :summative_activity, :assignments, to: :section_student_scores

  def initialize(params)
    super
    @sort_by = params[:sort_by]
    @order = params[:order]
    @concept_id = params[:concept_id]
  end

  def results
    @results ||= SectionPracticeTestAnalyzer.call(
      {
        lesson: lesson_focus,
        section: section,
        sort_by: @sort_by,
        order: @order,
        concept_id: @concept_id
      }
    )
  end

  def concepts_list
    concepts.slice(0, summative_concepts_count)
  end

  def summative_title
    activity.title
  end

  def formative_activities
    section_student_scores.formative_activities
  end

  def concepts_with_formative_activities
    {}.tap do |concepts_hash|
      summative_concepts.map do |concept|
        concepts_hash[concept] = formative_activities.find do |a|
          a.study_plan_concepts.any? { |c| c.reference_id == concept.reference_id }
        end
      end
    end
  end

  def summative_concepts_count
    activity.content_object.concepts.count
  end

  def summative_concepts
    latest_study_plan_concepts = section_student_scores.summative_concepts
                                                       .select('max(id) as id')
                                                       .group(:reference_id)
    section_student_scores.summative_concepts
                          .where(id: latest_study_plan_concepts)
                          .order(reference_id: :asc)
                          .limit(summative_concepts_count)
  end

  def summative_grade_for(student)
    section_student_scores.summative_grade_for(student)
  end

  def summative_grade_submitted_for(student)
    section_student_scores.summative_grade_submitted_for(student)
  end

  def missing_activities?
    results.error_code == FindLessonDiagnosticV2Activities::ACTIVITIES_NOT_PRESENT
  end
end
