class Instructor::FocusController < RequireInstructorController
  include ::GradebookV2Helper

  skip_before_action :set_current_program,
                     :set_current_focus,
                     :assign_course_sections_and_students_from_focus,
                     except: [:selector]

  def update
    @program_id = params[:program_id].to_s

    session[:focus] = {} if session[:focus].nil?
    session[:stashed_focus] = session[:focus]
    session[:stashed_return_to]= (CGI::unescape(params[:return_to]))

    if params[:focus].present?
      focus_type, focus_id = CGI::unescape(params[:focus]).split(',')
      course_id = focus_type == 'Course' ? focus_id.to_i : nil
      section_id = focus_type == 'Section' ? focus_id.to_i : nil

      sort_params = params[:sort]&.permit(:column, :direction, :category_id)&.to_h

      # (KS) does this eradicate the focus for all other programs ?
      session[:saved_focus] = session[:focus] = {
        @program_id => {
          'course_id' => course_id,
          'section_id' => section_id,
          'sort' => sort_params
        }
      }

      session[:activity_assignment] = nil
    else
      session[:focus][@program_id] = nil
      session[:saved_focus] = session[:focus]
    end
    @program = Program.find(@program_id)
    @current_focus = Focus.new(current_user, @program, session[:focus])

    respond_to do |format|
      format.html { redirect_to(return_to_url) }
      format.json do
        render json: {
          section_name: @current_focus.section_name,
          type_and_id: @current_focus.type_and_id
        }
      end
    end
  end

  def selector
    @sections = current_focus.sections.map do |section|
      {
        id: section.id,
        name: section.name
      }
    end
    @course_name = current_focus.course_name
    @feature_type = params[:feature_type]
    @redirect_url = case @feature_type
                    when 'assignment sets'
                      then instructor_assignment_sets_url(program_id: params[:program_id])
                    when 'individual assignment'
                      then instructor_individual_assignments_url(program_id: params[:program_id])
                    end
  end

  def redirect
    if session[:saved_focus]
      session[:focus] = session[:saved_focus]
      redirect_to("/gradebook/#{params[:program_id]}")
    else
      raise "No saved focus to redirect"
    end
  end


  def update_closed_course
    entity_type, entity_id= CGI::unescape(params[:selected_course_section]).split(',')
    course_id = entity_type == 'Course' ? entity_id.to_i : nil
    section_id = entity_type == 'Section' ? entity_id.to_i : nil

    session.merge!(
      focus: {
        params[:program_id] => {
          'course_id' => course_id,
          'section_id' => section_id
        }
      }
    )
    session[:closed_course_section] = {
      'course_id' => course_id,
      'section_id' => section_id
    }

    redirect_to(vhl_return_to_sanitizer(CGI::unescape(params[:return_to])))
#   redirect_to(CGI::unescape(params[:return_to]))
  end

  private def student_settings_link(section_id = nil)
    with_focused_course do |course|
      section_id ||= current_focus&.section_id

      # Student Settings cant be focused on a course without sections
      # In this case we redirect back to the return_to url specified
      if course.sections.empty?
        vhl_return_to_sanitizer(params[:return_to])
      elsif section_id
        section_student_settings_show_path(
          program_id: current_program.id,
          section_id:
        )
      else
        section_student_settings_show_path(
          program_id: current_program.id,
          section_id: course.sections.first.id
        )
      end
    end
  end

  private def return_to_url
    case params[:return_to]
    when /gradebook(?=.*reports)/ then reports_link
    when /gradebook(?=.*late.work)/ then late_work_link
    when %r{ gradebook(?=.*analytics/overview) } then analytics_link('overview')
    when %r{ gradebook(?=.*analytics/progress) } then analytics_link('progress')
    when /gradebook(?=.*progress)/ then analytics_link('progress')
    when /gradebook(?=.*standards)/ then analytics_link('standards')
    when /gradebook(?=.*analytics)/ then analytics_link('overview')
    when /gradebook(?!.*late.work)/ then gradebook_link
    when /roster/ then roster_link
    when /student-settings/ then student_settings_link
    else
      vhl_return_to_sanitizer(params[:return_to])
    end
  end
end
