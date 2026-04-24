class StudyPlanPresenter
  attr_accessor :attempt, :user_id, :activity, :has_vocab_access, :current_user

  delegate :cms_revision_id, :section_id, to: :attempt
  delegate :program, :content_object, to: :activity
  delegate :id, :title, to: :activity, prefix: true
  delegate :count, to: :formative_activities, prefix: true

  STUDY_PLAN_REDIRECT_NOTICE = 'Complete and submit the Practice Test to ' \
                               'receive your Study Plan.'.freeze
  COMPLETED_STUDY_PLAN_REDIRECT_NOTICE = 'You have been redirected to the correct ' \
                               'address for your Study Plan.'.freeze
  NON_STUDY_PLAN_REDIRECT_NOTICE = 'You have been redirected to the correct ' \
                                   'address for this activity.'.freeze

  def initialize(attempt, activity, user_id, has_vocab_access, current_user=nil)
    self.attempt = attempt
    self.activity = activity
    self.user_id = user_id
    self.has_vocab_access = has_vocab_access
    self.current_user = current_user
  end

  def show_study_plan?
    attempt.complete? && activity.has_summative_study_plan?
  end

  def study_plan_version
    return 'v1' unless activity.activity_type == 'diagnostic_v2'

    'v2'
  end

  def redirect_notice
    if show_study_plan?
      COMPLETED_STUDY_PLAN_REDIRECT_NOTICE
    elsif activity.has_summative_study_plan?
      STUDY_PLAN_REDIRECT_NOTICE
    else
      NON_STUDY_PLAN_REDIRECT_NOTICE
    end
  end

  def concepts
    @concepts ||= concepts_with_score
  end

  def lesson
    if activity.program.two_tier?
      activity.lesson.unit.lessons
    else
      [activity.lesson]
    end
  end

  def columns
    @columns ||= ['Concept'].tap do |names|
      formative_activities.each do |formative_activity|
        names << formative_activity.title
      end
      names << activity_title
      names << ['Score Change', 'Review', 'Practice']
    end.flatten
  end

  def individual_student_columns_for(concept_type)
    ['Concept'].tap do |names|
      formative_activities_by_concept_type(concept_type).each do |formative_activity|
        names << formative_activity.title
      end

      names << activity_title
      names << ['Score Change', 'Review', 'Practice']
    end.flatten
  end

  def formative_activities_by_concept_type(concept_type)
    return formative_activities if concept_type == 'all-concepts'

    formative_activities.select do |formative_activity|
      formative_activity.send("#{concept_type}?")
    end
  end

  def summative_activity?
    formative_activities.any?
  end

  def formative_activities
    return [] unless study_plan_with_concept_growth?

    @formative_activities ||= content_object.formative_activities.map do |content_object|
      StudyPlan::FormativeActivity.new(content_object, formative_activity_params)
    end.sort_by{ |activity| [activity.activity_lesson&.rank, activity.strand&.location] }
  end

  private def study_plan_with_concept_growth?
    activity.activity_type == 'diagnostic_v2'
  end

  private def concepts_with_score
    study_plan_concepts.map do |study_plan_concept|
      type = if study_plan_concept.recommendations.select(&:vocabulary?).any?
               'vocabulary'
             else
               'grammar'
             end

      StudyPlan::ConceptWithScores.new(study_plan_concept,
                                       concept_params,
                                       viewable_activities(type),
                                       formative_activities_by_concept_type('all-concepts').size)
    end
  end

  private def viewable_activities(type)
    if current_user.student?
      formative_activities
    else
      formative_activities_by_concept_type(type)
    end
  end

  private def program_id
    @program_id ||= program.id
  end

  private def concept_params
    @concept_params ||= {
      user_id: user_id,
      section_id: section_id,
      program_id: program_id,
      unit_id: lesson.first.unit_id,
      has_vocab_access: has_vocab_access
    }
  end

  private def formative_activity_params
    @formative_activity_params ||= concept_params.merge(
      lesson: lesson,
      summative_activity: activity
    )
  end

  private def study_plan_concepts
    @study_plan_concepts ||= StudyPlanConcept.includes(:recommendations)
                                             .where(activity_id: activity_id,
                                                    program_id: program_id,
                                                    cms_revision_id: cms_revision_id)
  end
end
