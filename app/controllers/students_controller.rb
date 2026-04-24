class StudentsController < ApplicationController
  before_action :require_user

  def enrollment_info
    if current_user.student?
      return head :forbidden
    end

    begin
      @school = current_user.schools.find(params[:school_id])
      @student = @school.students.find(params[:student_id])
    rescue ActiveRecord::RecordNotFound
      return head :forbidden
    end

    # TODO - refactor into presenter
    @thumb_url = @student.avatar_thumb_url
    render :layout => 'blank'
  end

  def student_info
    program = Program.find(params[:program_id])
    student = User.find(params[:id])
    section = Section.find(params[:section_id])
    gradebook_student = GradebookStudent.decorate(student, program, [section])
    @presenter = StudentInfoPresenter.new(gradebook_student, program, section)
    render :layout => false
  end

  def update_student_avatar
    student = User.find(params[:id])
    respond_to do |format|
      format.json do
        render json: { thumbnail_path: student.avatar_thumb_url, avatar_path: student.avatar_image_url }
      end
    end
  end
end
