class Ua::UserDataDeleterController < Ua::ActiveResourceController
  def delete_user_data
    user_id = User.where(guid: params[:user_guid]).pluck(:id).first
    if user_id
      # How does UA track this?  Does it even need to?
      UserDataDeleterWorker.perform_async(user_id)
      head :ok
    else
      head :not_found
    end
  end
end
