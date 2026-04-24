class AnnouncementsController < ApplicationController
  before_action :require_user
  before_action :require_program_access
  before_action :assign_menu_coords
  before_action :archived_program_redirect

  include HasHelp
  before_action :contextual_help_url, only: %i[index show]

  include SectionHeader
  before_action :assign_section_header, only: %i[index show]

  layout 'music_v1/default'

  def index
    session[:activity_return] = {
      'label' => 'Return to Announcements', 'url' => section_announcements_path
    }
    @page_title = 'Announcements'
  end

  def show
    set_activity_return_link
    @announcement = Announcement.find(params[:id])
    @section = current_section
    @announcement.dismiss_notifications_for_user_and_section(current_user, current_section)
    @page_title = 'Announcement Details'
  end

  def download
    @announcement = Announcement.find(params[:id])
    redirect_to @announcement.signed_url
  end

  private def assign_menu_coords
    @menu_location = 'communication'
  end

  private def set_activity_return_link
    if session[:activity_return]
      @return_label = session[:activity_return]['label']
      @return_url = session[:activity_return]['url']
    else
      @return_label = 'Return to Dashboard'
      @return_url = course_section_path(current_program, current_section)
    end
  end
end
