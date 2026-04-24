class MobileAppController < ApplicationController
  before_action :require_user
  before_action :require_program_access
  before_action :require_mobile_app_access
  before_action :set_current_focus, if: :current_user_is_instructor?
  before_action :set_page_header

  def set_page_header
    @page_header = 'Practice Partner App'
  end

  def show
  end

  def require_mobile_app_access
    redirect_to ua_home_path unless access_guardian.has_mobile_app?
  end
end
