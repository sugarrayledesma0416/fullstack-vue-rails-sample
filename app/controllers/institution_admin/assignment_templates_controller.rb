class InstitutionAdmin::AssignmentTemplatesController < Instructor::AssignmentsController
  include TemplateFocusable

  before_action :show_templates_return_bar

  def index
    if current_focus.has_atleast_one_actionable_section?
      @calendar_presenter = CalendarPresenter.build(current_user,
                                                    month_date(params[:month]),
                                                    current_program,
                                                    { focus: current_focus })
      @page_title = 'Calendar'
    end
  end

  def new
    course = Course.enterprise.find(params[:course_id])

    if current_focus.has_atleast_one_actionable_section?
      @assignment_filter_presenter = AssignmentFilterPresenter.new(@program,
                                                                   @sections,
                                                                   course,
                                                                   current_user,
                                                                   current_focus,
                                                                   params[:current_activities_count])

      @calendar_presenter = CalendarPresenter.build(current_user,
                                                    month_date(params[:month]),
                                                    current_program,
                                                    focus: current_focus)

      @page_title = 'Calendar'
    end
    render
  end
end
