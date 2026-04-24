class StrandsController < ApplicationController
  def index
    lesson = Lesson.find_by_id(params[:override_lesson_id] || params[:lesson_id])
    @strands = lesson.strands
    render :layout => false
  end
end