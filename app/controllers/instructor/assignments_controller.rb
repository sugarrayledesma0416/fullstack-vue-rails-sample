class Instructor::AssignmentsController < RequireInstructorController

  include HasHelp
  before_action :assign_menu_coords
  before_action :contextual_help_url, only: :new
  before_action :redirect_if_assistant, only: :new

  def index
    if current_focus.has_atleast_one_actionable_section?
      @calendar_presenter = CalendarPresenter.build(current_user, month_date(params[:month]), current_program, {:focus => current_focus})
      @page_title = 'Assignment Calendar'
    end
  end

  def assign_menu_coords
    @menu_location = 'content'
  end

  def new
    if current_focus.has_atleast_one_actionable_section?
      @assignment_filter_presenter = AssignmentFilterPresenter.new(current_program,
                                                                   @sections,
                                                                   @course,
                                                                   current_user,
                                                                   current_focus,
                                                                   params[:current_activities_count])

      @calendar_presenter = CalendarPresenter.build(current_user, month_date(params[:month]),
                                                  current_program, {:focus => current_focus})

      @page_title = 'Start Assigning'
    end
    render
  end

  def show_calendar
    @calendar_presenter = CalendarPresenter.build(
      current_user,
      month_date(params[:year_month]),
      current_program,
      focus: current_focus)

    respond_to do |format|
      format.html do
        render 'instructor/calendar/_event_calendar',
               layout: false,
               locals: { calendar_presenter: @calendar_presenter }
      end

      format.json do
        page_content = render_to_string(
          template: 'instructor/calendar/_event_calendar.html.erb',
          layout: false,
          locals: { calendar_presenter: @calendar_presenter })
        render json: {
          message: flash[:notice],
          calendar_html: page_content
        }
      end
    end
  end

  def show_more
    assignment_filter_presenter = AssignmentFilterPresenter.new(current_program,
                                                                   @sections,
                                                                   @course,
                                                                   current_user,
                                                                   current_focus,
                                                                   params[:current_activities_count])
    respond_to do |format|
      format.js do
        render :partial => 'unassigned_activities', :layout => false, :locals => {:presenter => assignment_filter_presenter}
      end
    end
  end

  private

  def month_date(yearmonth)
    if yearmonth
      (year, month) = yearmonth.split('-')
      Date.new(year.to_i, month.to_i, 1)
    else
      Time.zone.now.to_date
    end
  end

end
