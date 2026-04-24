class SectionPracticeTestAnalyzer
  extend LightService::Organizer

  ACTIONS = [
    ::FindLessonDiagnosticV2Activities,
    ::FindActivityConceptScoresAndGrades,
    ::SortStudents
  ].freeze

  # Set initial context for actions organized by the organizer
  def self.call(params)
    with(
      {
        lesson: params[:lesson],
        section: params[:section],
        table_sort_by: params[:sort_by],
        order: params[:order],
        concept_id: params[:concept_id]
      }
    ).reduce(ACTIONS)
  end
end
