class MixAndMatchCreatedActivityPresenter
  include Rails.application.routes.url_helpers

  UNSAFE_TYPES = %w[audio_composition composition partner_chat recording_v2].freeze

  attr_accessor :course_id, :created_activity_id, :lesson_id, :program_id

  def initialize(course_id:, created_activity_id:, lesson_id:, program_id:)
    self.course_id = course_id
    self.created_activity_id = created_activity_id
    self.lesson_id = lesson_id
    self.program_id = program_id
  end

  def activity_data
    lesson = activities&.first&.lesson
    return [] unless lesson

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
    common_scope.joins(:course_library_activities).where(
      course_library_activities: { course_id: course_id }
    )
  end

  private def common_scope
    if created_activity_id.present?
      base_scope.where('activities.id <> ?', created_activity_id)
    else
      base_scope
    end
  end

  private def base_scope
    Activity.select(
      'activities.*, concepts.id as strand_id, concepts.name as concept_name'
    ).joins(:concept).where(
      activities: { lesson_id: lesson_id }
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
      url: instructor_mix_and_match_created_activities_path(
        lesson_id: lesson_id, program_id: program_id,
        course_id: course_id, created_activity_id: created_activity_id
      )
    }
  end
end
