class UsersController < ApplicationController
  include CartridgeViewable

  before_action :require_user

  def update_gender
    user = User.find(params[:id])
    user.gender = params[:user]['gender']
    user.save!
    respond_to do |format|
      format.js do
        render plain: 'user updated', status: :ok
      end
    end
  end
end
