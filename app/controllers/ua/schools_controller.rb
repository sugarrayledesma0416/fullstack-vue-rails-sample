class Ua::SchoolsController < Ua::ActiveResourceController
  def merge
    # look up the SchoolUser and Course by guid and get their ids
    assign_school_ids
    # we want to bypass course hooks and school_users hooks (course and schools_users ua records have been previously updated)
    SchoolUser.where(school_id: @old_school_id).update_all(school_id: @new_school_id)
    Course.where(school_id: @old_school_id).update_all(school_id: @new_school_id)
    # update all the gradebook objects in this school
    GbSchoolMergeWorker.perform_async(
      'old_school_id' => @old_school_id,
      'new_school_id' => @new_school_id
    )
    head :ok
  end

  private def assign_school_ids
    @old_school_id = school_id_from_guid(params[:old_school_guid])
    @new_school_id = school_id_from_guid(params[:new_school_guid])
  end

  private def school_id_from_guid(school_guid)
    school_id = School.where(guid: school_guid).pluck(:id).first

    # Disallow school_id = nil, which will set the new school ID to null.
    raise "#{school_guid} is not a valid school GUID" unless school_id

    school_id
  end
end
