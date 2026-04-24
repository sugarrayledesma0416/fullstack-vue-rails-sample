class Instructor::ActivityHelpRequestsController < RequireInstructorController
  # The feature is not used by Common Cartridge users
  # but the grading workflow calls this controller.
  include CartridgeViewable
  skip_before_action :assign_course_sections_and_students_from_focus

  def index
    # Angular has a problem with passing arrays, but it's fixed it version 1.1.1 - Note this pull request: https://github.com/angular/angular.js/pull/1364
    # The params[:student_ids].values code should be refactored as soon as we update to 1.1.1.
    student_ids = params[:student_ids].values
    help_requests = HelpRequest.instructor_respondable_by_section_user_activity_and_question(current_focus.sections,
                                                                                             student_ids,
                                                                                             params[:activity_id],
                                                                                             params[:question_id]).include_users

    render :json => help_requests.to_json(HelpRequest::ACTIVITY_JSON_OPTIONS)
  end

  def update
    help_request = HelpRequest.find(params[:id])
    attributes = safe_help_request_attributes(params)
    help_request.update!(attributes)
    help_request.dispatch_notification
    render :json => help_request.to_json(HelpRequest::ACTIVITY_JSON_OPTIONS)
  end

  private def safe_help_request_attributes(params)
    params.permit(:status, :instructor_comment, :read_by_student)
      .merge(processed_by: current_user.id, processed_at: Time.now)
  end

end
