class NotificationsController < ApplicationController
  before_action :require_user
  before_action :require_program_access, except: :json_index
  before_action :assign_menu_coords, except: :json_index
  before_action :archived_program_redirect, except: :json_index

  include HasHelp
  before_action :contextual_help_url, only: %i[index show]

  include SectionHeader
  before_action :assign_section_header, only: %i[index show]

  layout 'music_v1/default'

  def index
    session[:activity_return] = {
      'label' => 'Return to Notifications', 'url' => section_notifications_path
    }
    @page_title = 'Notifications'
  end

  # Using a separate action instead of a respond_to block in the index
  # action because most of the before_actions don't apply.
  def json_index
    collection = NotificationCollection.new(
      current_program, current_section, current_user
    )
    render json: collection.serialize
  end

  def show
    @notification = Notification.find(params[:id])
    redirect_to redirect_path(@notification)
  end

  private def assign_menu_coords
    @menu_location = 'communication'
  end

  private def redirect_path(notification)
    case notification.redirect_type
    when :internal_activity
      section_activity_path(notification.section_id, notification.activity_id)
    when :external_activity
      section_external_activity_path(
        notification.section_id, notification.activity_id
      )
    when :announcement
      announcement_redirect_path(notification)
    when :study_plan
      section_study_plan_concepts_path(
        notification.section_id, notification.activity_id
      )
    when :study_plan_v2
      section_activity_path(notification.section_id, notification.activity_id)
    end
  end

  private def announcement_redirect_path(notification)
    path_args = {
      id: notification.announcement_id, section_id: notification.section_id
    }
    if supersite_junior?
      jr_section_announcement_path(path_args)
    else
      section_announcement_path(path_args)
    end
  end
end
