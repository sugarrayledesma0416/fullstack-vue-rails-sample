class Student::AssessmentAccessController < ApplicationController
  before_action :require_user

  def unlock_assessment
    validator = PasswordAttemptValidator.new(
      current_user,
      filter_params[:section_id],
      filter_params[:activity_id],
      filter_params[:assessment_password]
    )
    validator.log_password_attempt

    if validator.correct?
      session[:unlocked_assessments] ||= []
      session[:unlocked_assessments] << filter_params[:activity_id].to_i
      render json: { status: :ok, success: true }
    else
      render json: { error: 'The password you entered is incorrect.' }
    end
  end

  private def filter_params
    params.permit(
      :section_id,
      :activity_id,
      :assessment_password
    ).to_h.symbolize_keys
  end
end
