class UserDataDeleterWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  sidekiq_options retry: 5, failures: :exhausted

  def perform(user_id)
    @user_id = user_id
    UserDataDeleter.new(user_id).delete_user_data
  end
end
