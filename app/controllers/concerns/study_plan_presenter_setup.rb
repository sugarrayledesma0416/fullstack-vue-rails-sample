module StudyPlanPresenterSetup
  extend ActiveSupport::Concern

  included do
    helper_method :get_study_plan_presenter
    helper_method :analytics_view?
    helper_method :activity_view?
  end

  def get_study_plan_presenter(attempt, presenter = nil, user = current_user)
    return presenter if presenter.class == StudyPlanPresenter

    has_vocab_access = current_program.has_vocab_tools? && access_guardian.has_vocab_tools?
    StudyPlanPresenter.new(attempt, @activity, user.id, has_vocab_access, current_user)
  end

  def analytics_view?
    controller_name == 'practice_test'
  end

  def activity_view?
    controller_name == 'activities'
  end
end
