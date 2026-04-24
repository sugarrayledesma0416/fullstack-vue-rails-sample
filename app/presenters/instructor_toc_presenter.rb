class InstructorTocPresenter
  include InstructorTocPresentation
  # "Common" means shared between Supersite Junior and non-Supersite Junior
  include TocPresenterCommon
  # "Standard" means "not Supersite Junior"
  include StandardTocPresentation
  include InstructorAssignableActivity
  include Lti::TocDeepLinking

  attr_accessor :current_user,
                :current_program,
                :current_focus,
                :lesson,
                :program,
                :session

  def initialize(program,
                 user,
                 current_focus,
                 req_params,
                 session)
    raise "not all parameters are valid" if !program ||
                                            !user ||
                                            !req_params

    self.current_user = user
    self.current_focus = current_focus
    self.course = current_focus.course if current_focus
    self.program = program
    self.session = session
    @req_params = req_params
    @saved_location = session[:saved_location]
  end

  def course
    current_focus.course
  end

  def assignable_view?
    assignment_validator.any_assignable?(activities)
  end

  def base_url(options={})
    Rails.application.routes.url_helpers.instructor_toc_path(program.id, options)
  end

  def component_header_class(component_activities)
    if any_assignable?(component_activities)
      'toc_location_component'
    else
      'toc_location_component unassignable_component'
    end
  end

  def toc_path(*args)
    Rails.application.routes.url_helpers.instructor_toc_path(program.id, *args)
  end

  def new_activity_link_presenter(view)
    Instructor::CreatedActivity::NewActivityLinkTocPresenter.new(view, self)
  end
end
