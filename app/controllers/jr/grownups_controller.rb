module Jr
  class GrownupsController < ApplicationController
    before_action :require_user

    layout 'music_v1/default'

    def show
      @menu_location = 'grownups'
      @sub_location = 'home'
      @page_title = 'Welcome to the School-Home Connection'

      session[:activity_return] = {
        'label' => 'Return to Grown-ups Home',
        'url' => jr_section_grownups_path(section_id: current_section.id)
      }
    end
  end
end
