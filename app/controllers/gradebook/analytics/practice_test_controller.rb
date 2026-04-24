class Gradebook::Analytics::PracticeTestController < RequireInstructorController
  helper MaestroActivityEngine::ActivitiesHelper
  helper MaestroActivityEngine::DiagnosticV2Helper
  layout 'music_v1/responsive'

  include StudyPlanPresenterSetup

  def individual_student
    @student_practice_test_presenter = Gradebook::StudentPracticeTestPresenter.new(params)

    @activity ||= @student_practice_test_presenter.activity
    @attempt ||= @student_practice_test_presenter.attempt
    @results ||= @attempt&.results
    render :layout => 'music_v1/minimal'
  end

  def show
    @section_practice_test_presenter = Gradebook::SectionPracticeTestPresenter.new(params)
    @score_presenter = Gradebook::AnalyticsScorePresenter.new(
      @section_practice_test_presenter.section
    )

    # If summative and formative diagnostic_v2 activities were not found, failure? will be
    # true, but we want to show the user a message instead of raising an error. For all other
    # problems, we will raise an error.
    unless @section_practice_test_presenter.missing_activities?
      msg = 'There was a problem displaying the Practice Test results'
      raise msg if @section_practice_test_presenter.failure?
    end
  end
end
