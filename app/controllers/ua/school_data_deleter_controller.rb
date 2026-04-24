class Ua::SchoolDataDeleterController < Ua::ActiveResourceController
  def delete_school_data
    school_id = School.where(guid: params[:school_guid]).pluck(:id).first
    if school_id
      SchoolDataDeleterWorker.perform_async(school_id)
      head :ok
    else
      head :not_found
    end
  end
end
