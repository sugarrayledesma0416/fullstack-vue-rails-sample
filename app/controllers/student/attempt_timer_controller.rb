class Student::AttemptTimerController < ApplicationController
  before_action :require_user
  def time_sync 
    attempt = Attempt.find(params[:id])
    render :json => { time_left: attempt.time_left_in_seconds }
  end
end
