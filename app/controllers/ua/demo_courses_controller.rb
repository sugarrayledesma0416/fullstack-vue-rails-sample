class Ua::DemoCoursesController < Ua::ActiveResourceController

  def create
    # switch out the incoming guids for ids so as to
    # miminally disrupt the existing workflow
    new_params = replace_guid_with_ids(params)
    demo_course_creator = DemoCourseBuild::Creator.new(new_params.stringify_keys)
    if demo_course_creator.valid?
      DemoCourseCreatorWorker.perform_async(new_params)
    end
    respond_to do |format|
      format.json do
        render :json => demo_course_creator.message, :status => demo_course_creator.status
      end
    end
  end

  private def replace_guid_with_ids(params)
    # don't search for objects if guids are missing
    # DemoCourseCreator eventually checks for missing
    # params and returns false for valid?
    owner_id = User.where(guid:params[:owner_guid]).pluck(:id) unless params[:owner_guid].blank?
    student_ids = User.where(guid:params[:student_guids]).pluck(:id) unless params[:student_guids].blank?
    {
      'owner_id' => owner_id,
      'program_id' => params[:program_id],
      'student_ids' => student_ids
    }
  end
end
