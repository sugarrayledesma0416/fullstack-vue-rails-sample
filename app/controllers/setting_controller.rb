class SettingController < ApplicationController
  before_action :require_user

  def sort_courses
    respond_to do |format|
      format.json do
        current_user.set("course_order_#{params[:program_id]}", params[:course_order])
        head :ok
      end
    end
  end
end
