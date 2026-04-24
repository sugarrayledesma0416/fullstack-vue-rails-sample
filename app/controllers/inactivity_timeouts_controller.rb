class InactivityTimeoutsController < ApplicationController
  def update_session
    response.headers['Etag'] = '' # clear etags to prevent caching

    if current_user
      if inactivity_timeout.enabled_in_selected_school? || inactivity_timeout.enabled_in_any_school?
        inactivity_timeout.update_last_activity_time(timeout_params[:last_activity_time_epoch].to_i)
      end

      render json: { ttl_to_timeout: inactivity_timeout.timeout_in }
    else
      render json: { ttl_to_timeout: 0 }
    end
  end

  def log_out
    if current_user.present?
      persistent_session&.delete
      reset_session
    end
    redirect_to ua_logout_url
  end

  private def ua_logout_url
    URI(UA_URL).tap do |uri|
      uri.path = '/logout'
      uri.query = URI.encode_www_form(
        msg_type: 'error',
        flash_msg: 'You were logged out of your school due to inactivity.'
      )
    end.to_s
  end

  private def timeout_params
    params.require(:inactivity_timeout).permit(
      :last_activity_time_epoch,
      :school_id
    )
  end

  private def inactivity_timeout
    return @inactivity_timeout if defined? @inactivity_timeout

    # Use the school from the params if the user belongs to this school.
    # If it does not and only belongs to one school, use that school.
    # Otherwise, use nil for the school.
    school_from_params = current_user.schools.find_by(id: timeout_params[:school_id])
    school = if school_from_params
               school_from_params
             elsif current_user.schools.count == 1
               current_user.schools.first
             end

    @inactivity_timeout = InactivityTimeout.new(
      session: persistent_session,
      user: current_user,
      school:
    )
  end
end
