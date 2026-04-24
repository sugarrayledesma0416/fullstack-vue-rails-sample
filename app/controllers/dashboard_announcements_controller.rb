class DashboardAnnouncementsController < ApplicationController
  before_action :require_user
  before_action :assign_announcement, only: %i[destroy edit update]
  before_action :visible_announcement_ids, only: %i[new create edit update]
  before_action :update_visible_announcement, only: %i[create update]

  def index
    @dashboard_announcements = DashboardAnnouncement.all
  end

  def new
    @dashboard_announcement = DashboardAnnouncement.new
  end

  def create
    @dashboard_announcement = DashboardAnnouncement.create(dashboard_announcement_params)
    if @dashboard_announcement.save
      flash[:notice] = 'The announcement was successfully created'
      redirect_to dashboard_announcements_path
    else
      flash.now[:error] = 'Could not create the announcement'
      render :new
    end
  end

  def edit
    @dashboard_announcement = DashboardAnnouncement.find(params[:id])
  end

  def update
    if @dashboard_announcement.update(dashboard_announcement_params)
      flash[:notice] = 'The announcement was successfully modified'
      redirect_to dashboard_announcements_path
    else
      flash.now[:error] = 'Could not modify the announcement'
      render :edit
    end
  end

  def destroy
    @dashboard_announcement.destroy
    flash[:notice] = 'The announcement was successfully deleted'
    redirect_to dashboard_announcements_path
  end

  private def assign_announcement
    @dashboard_announcement = DashboardAnnouncement.find(params[:id])
  end

  private def visible_announcement_ids
    @visible = {}
    @visible[:vol] = DashboardAnnouncement.where(vol: true).limit(1).pluck(:id).last
    @visible[:supersite] = DashboardAnnouncement.where(supersite: true).limit(1).pluck(:id).last
  end

  private def new_visible_announcement?(platform)
    # Checks if the visible announcement is the one being edited
    @visible[platform] != params[:id].to_i
  end

  private def update_visible_announcement
    @visible.each_key do |platform|
      if params[:dashboard_announcement][platform] == '1' && new_visible_announcement?(platform)
        DashboardAnnouncement.remove_previous_announcement(platform)
      end
    end
  end

  private def dashboard_announcement_params
    params.require(:dashboard_announcement).permit(
      :title,
      :body,
      :external_url,
      :link_text,
      :supersite,
      :vol
    )
  end
end
