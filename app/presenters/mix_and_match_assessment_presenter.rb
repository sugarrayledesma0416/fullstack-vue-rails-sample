class MixAndMatchAssessmentPresenter
  include Rails.application.routes.url_helpers

  UNSAFE_TYPES = %w[audio_composition composition partner_chat recording_v2].freeze

  attr_accessor :course_id, :current_assessment_id, :lesson_id, :program_id, :current_user

  def initialize(course_id:, current_assessment_id:, lesson_id:, program_id:, current_user:)
    self.course_id = course_id
    self.current_assessment_id = current_assessment_id
    self.lesson_id = lesson_id
    self.program_id = program_id
    self.current_user = current_user
  end

  def activity_data
    lesson = activities.first.lesson
    activities.group_by(&:strand_id).map do |strand_id, entries|
      strand = lesson.strand_for_toc_location(strand_id)

      strand && {
        id: strand_id,
        name: strand.title,
        concept_name: entries.first.concept_name,
        activities: entries.map { |activity| activity_hash(activity) }
      }
    end.compact
  end

  private def activities
    vhl_activities + instructor_activities
  end

  private def vhl_activities
    common_scope.where('activities.cms_revision_id is not null')
  end

  private def instructor_activities
    common_scope
      .where(
        'activities.instructor_revision_id IS NOT NULL
         AND activities.instructor_id = ?', current_user.id
      )
      .where(hide_from_my_content: false)
  end

  private def common_scope
    if current_assessment_id
      base_scope.where('activities.id <> ?', current_assessment_id)
    else
      base_scope
    end
  end

  private def base_scope
    Activity.select(
      'activities.*, concepts.id as strand_id, concepts.name as concept_name'
    ).joins(:concept).where(
      activities: { lesson_id: lesson_id }, concepts: { assessment: true }
    ).where(
      activities: { activity_type: 'exam' }
    ).order('concepts.rank, activities.toc_location_rank')
  end

  private def icons(activity)
    activity.icon.split(',').tap do |memo|
      memo << 'instructor_graded' if activity.instructor_graded?
    end
  end

  private def activity_hash(activity)
    {
      icons: icons(activity),
      id: activity.id,
      title: activity.title,
      url: instructor_mix_and_match_assessment_path(
        id: activity.id, program_id: program_id
      )
    }
  end
end
