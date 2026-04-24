class UserReadingsController < ApplicationController
  before_action :require_user
  before_action :require_program_access

  def update
    @user_reading = UserReading.find(params[:id])
    @user_reading.update(viewed: true) if owner?
    render json: {}, status: :ok
  end

  def owner?
    @user_reading.user_id == current_user.id
  end
  private :owner?
end
