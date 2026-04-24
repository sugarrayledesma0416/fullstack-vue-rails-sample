class WorkersController < ApplicationController
  before_action :require_user, only: :show
  before_action :require_instructor, only: :show

  def show
    status = Sidekiq::Status.get_all(params[:id])
    render json: status
  end
end
