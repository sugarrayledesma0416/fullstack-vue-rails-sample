class QuestionBankAssessmentPresenter
  include Rails.application.routes.url_helpers

  attr_accessor :lesson_id, :program_id

  def initialize(lesson_id:, program_id:)
    self.lesson_id = lesson_id
    self.program_id = program_id
  end

  def activity_data
    activities.group_by(&:strand_id).map do |strand_id, entries|
      {
        id: strand_id,
        name: entries.first.strand_name.strip_tags.html_decode,
        activities: entries.map { |activity| activity_hash(activity) }
      }
    end
  end

  private def activities
    QuestionBank.select(
      'activities.*, concepts.id as strand_id, concepts.name as strand_name'
    ).joins(question_bank_topic: :concepts).where(
      concepts: { lesson_id: lesson_id }
    ).group('activities.id').order(
      'concepts.rank, activities.title'
    ).reject { |activity| activity.current_live_revision.nil? }
  end

  private def activity_hash(activity)
    {
      id: activity.id,
      title: activity.title,
      url: instructor_mix_and_match_assessment_path(
        id: activity.id, program_id: program_id
      )
    }
  end
end
