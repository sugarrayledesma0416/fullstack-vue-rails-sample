module SmartbookActivityViewable
  private def assign_santillana_book_iframe_src(max_attempts: nil, modifiable: true)
    if @activity.activity_type == 'smart_book'
      assign_smart_book_iframe_src(max_attempts, modifiable)
    else
      assign_static_book_iframe_src
    end
  end

  private def assign_smart_book_iframe_src(max_attempts, modifiable)
    user_token = XapiUserToken.new(
      attempt_id: @attempt.id,
      user_id: current_user.id,
      state_modifiable: xapi_state_modifiable? && modifiable
    )
    @iframe_src = @activity.content_object.iframe_src(
      request: request,
      mbox: user_token.mbox,
      activity_id: @activity.id,
      auth: Xapi::BasicAuthCredential.generate_credentials(current_user),
      role: smartbook_user_role,
      max_attempts: max_attempts
    )
  end

  private def assign_static_book_iframe_src
    @iframe_src = @activity.content_object.iframe_src
  end

  # this allows an instructor to view a smart book activity
  # without saving modifications to the viewing state;
  # this will faciliate grading so that an instructor can view
  # a student's responses within the smartbook content without modifying state.
  private def xapi_state_modifiable?
    current_user.student?
  end

  def smartbook_user_role
    if current_user.student?
      MaestroActivityEngine::ActivityContent::SmartBookContent::STUDENT_ROLE
    else
      MaestroActivityEngine::ActivityContent::SmartBookContent::INSTRUCTOR_ROLE
    end
  end
end
