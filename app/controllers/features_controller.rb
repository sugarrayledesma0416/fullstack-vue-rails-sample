class FeaturesController < ApplicationController
  before_action :require_user

  def toggle_program_nav
    if cookies[:feature_program_nav] == 'v2'
      cookies[:feature_program_nav] = 'v1'
      flash[:notice] = 'Switched to old navigation style'
    else
      cookies[:feature_program_nav] = 'v2'
      flash[:notice] = 'Switched to new navigation style'
    end
    redirect_back_or_default(best_default_path)
  end
end
