module Support
  class CoursesController < ApplicationController
    before_action :deny_live_environment
    before_action :require_user
    before_action :assign_course, except: :index
    authorize_resource

    def index
      if params[:id].present?
        if Course.exists?(params[:id])
          redirect_to edit_support_course_path(params[:id])
        else
          flash[:error] = "No course with id #{params[:id]} found"
        end
      end
    end

    def edit; end

    def update
      end_date = params[:course][:end_date]
      @course.allow_past_end_date = true
      @course.end_date = end_date
      if @course.save
        flash[:notice] = "Course id: #{params[:id]} updated with new end date: #{end_date}."
        redirect_to edit_support_course_path(params[:id])
      else
        flash[:error] = "#{end_date} is an invalid date."
        render :edit
      end
    end

    private def deny_live_environment
      return unless Rails.env.live?

      render text: 'This tool cannot be used in a live environment'
    end

    private def assign_course
      @course = Course.find(params[:id])
    end
  end
end
