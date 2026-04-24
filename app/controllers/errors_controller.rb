class ErrorsController < ApplicationController
  before_action :require_user
  before_action :assign_menu_coords
  before_action :set_current_focus, :unless => :current_user_is_student?

  def activity_privileges
    @section = current_section
  end

  def assign_menu_coords
    @menu_location = {:level_1 => 'errors'}
  end
  private :assign_menu_coords

end
