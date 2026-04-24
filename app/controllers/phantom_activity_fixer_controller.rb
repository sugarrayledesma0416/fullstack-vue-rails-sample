class PhantomActivityFixerController < ApplicationController
  before_action :require_user
  before_action :initialize_tool

  def initialize_tool
    authorize! :create, PhantomActivityFixerController
    authorize! :index, PhantomActivityFixerController
  end

  def index
  end

  def create
    phantom_activity = PhantomActivityFixer.new(params[:activity_first].to_i,
                                                params[:activity_second].to_i)
    phantom_activity.process
    if phantom_activity.errors.empty?
      flash[:notice] = 'The process has finished successfully.'
    else
      flash[:error] = phantom_activity.errors.first
    end
    redirect_to action: 'index'
  end
end
