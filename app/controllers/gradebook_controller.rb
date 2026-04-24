class GradebookController < RequireInstructorController
  include HasHelp

  before_action :contextual_help_url
  before_action :assign_session_activity_return
  before_action :assign_menu_coords
  before_action :validate_and_assign_return_to, only: :confirm_actions
  before_action :assign_grade_display_style, except: %i[actions]
  before_action :require_school_access, except: :confirm_actions

  def assign_menu_coords
    @menu_location = 'grades'
  end

  def confirm_actions
    @action = params[:other_actions]
    session[:select_students] = params[:select_students]
    @view_type = (params[:view_type])?(params[:view_type]):("Gradebook")

    case @action
    when 'drop_students'
      return redirect_to(gradebook_drop_students_edit_path(:coords => params[:coords] ,
                                                           :return_to => @return_to))
    when 'add_external_activity'
      return redirect_to(new_gradebook_external_activity_path(params[:coords]))
    when (nil or '')
      flash[:error] = 'No action selected'
    else
      flash[:error] = "Action #{@action} not defined"
    end

    return (redirect_to(vhl_return_to_sanitizer(@return_to))) if flash[:error]
    @page_header = format_page_header(@action,@students_submitted)
    return render :layout => 'popup_with_style' if @view_type == "student_view"
    return render :layout => 'full_width_body'
  end

  def actions
    session[:select_students] = params[:select_students]
    if params[:commit] == 'Confirm' ||  params[:commit] == 'Undo'
      case params[:other_actions]
      when 'drop_students'
        raise "This functionality should not be used"
      when 'sort'
        session[:select_students] = params[:select_students]
        add_sort_to_focus(params)
      when 'undo_drop'
        raise "This functionality should not be used"
      when (nil or '')
        session[:select_students] = params[:select_students]
        flash[:error] = 'No action selected'
      else
        flash[:error] = "Action #{params[:other_actions]} not defined"
      end
    else
      flash[:notice] = "#{params[:other_actions].humanize} cancelled."
    end

    raise "return_to param cannot be blank" if params[:return_to].blank?
    redirect_to(vhl_return_to_sanitizer(params[:return_to]))
  end

  private

  def flash_for_empty_gradebook
    notices = []
    notices << "You do not have any students in this #{current_focus.type}." if @students.empty?
    notices << 'You have not created any assignments for this area of your gradebook.' if @gradebook_headers.empty?
    flash.now[:notice] = notices.join('<br/>') unless notices.empty?
  end


  def format_page_header(action,list)
    case action
      when 'drop_students'
       msg = "drop_student".humanize()
       msg = msg.pluralize if list.count > 1
       "confirm <span>#{msg}</span>"
      else
       "confirm <span>#{action.humanize()}</span>"
    end
  end

  def add_sort_to_focus(params)
    session[:focus] ||= {}

    focus_params = session[:focus][params[:program_id].to_i]
    focus_params ||= {}

    sort_params = {:column => params[:column],
                   :direction => params[:direction],
                   :category_id => params[:category_id] }
    session[:focus][params[:program_id].to_i] = focus_params.merge(:sort => sort_params)
  end

  def correct_category_id_and_redirect(err)
    if request.url =~ /category_id/
      redirect_to(request.url.gsub(/category_id=\d+/, "category_id=#{err.message}"))
    else
      redirect_to(request.url.gsub(/category\/\d+/, "category/#{err.message}"))
    end
  end

  def selected_tab
    section_id = session[:focus].first[1][:section_id].to_i
    section = Section.find_by_id(section_id)
    return "<b>#{section.name}</b>" if section
    course_id = session[:focus].first[1][:course_id].to_i
    course =Course.find_by_id(course_id)
    return "<b>#{course.name}</b>" if course
    return "<b> All Courses </b>"
  end

  def current_path(err_msg)
    lesson = session[:stashed_return_to].match(/(\/lesson\/[0-9]*)/) if session[:stashed_return_to]
    if lesson
      lesson = Lesson.find_by_id(lesson.to_s.gsub('/lesson/',''))
      return "Lesson <b>#{lesson.name}</b>" if lesson
    end

    if session[:stashed_return_to] =~ /\/category\/([0-9]*)/
      category = Category.find_by_id($1)
      return "Category <b>#{category.name}</b>" if category
    end
  end

  def format_focus_error(err_msg)
    "<div class=\"grade_book_redirect_error\">
    #{selected_tab} does not have a #{current_path(err_msg)}. <a href=\"/instructor/focus_redirect/#{params[:program_id]}\" class=\"flash_error_links\"> Click here</a> to go to the gradebook home page for #{selected_tab}.
      </div>"
  end

  def assign_session_activity_return
    session[:activity_return] = { 'label' => 'Return to Gradebook', 'url' => current_path('') }
  end

  def assign_grade_display_style
    @grade_display_style = current_user.setting(Setting::Gradebook::GradeDisplayStyle)
  end

  def require_school_access
    # If dev features are not enabled, if a gradebook-v2-school course is focused,
    #   redirect to gradebook v2. Path depends on whether we know the section.

    # As a dev, it's OK to be able to access both gradebooks for comparison.
    if !(Rails.application.config.enable_gradebook_dev_features || cookies[:dev])
      if @course
        if current_focus.section
          redirect_to gradebook_engine.course_section_path(current_program.id,
                                                           @course.id,
                                                           current_focus.section.id)
        else
          redirect_to gradebook_engine.course_path(current_program.id,
                                                   @course.id)
        end
      end
    end
  end
end
