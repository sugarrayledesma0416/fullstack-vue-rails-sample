module Jr
  class AnnouncementsController < ::AnnouncementsController
    def show
      super
      @page_title = 'Announcement'
    end

    private def assign_menu_coords
      @menu_location = 'grownups'
    end

    private def set_activity_return_link
      if session[:activity_return]
        @return_label = session[:activity_return]['label']
        @return_url = session[:activity_return]['url']
      else
        @return_label = 'Return to Grown-ups Home'
        @return_url = jr_section_grownups_path(section_id: current_section.id)
      end
    end
  end
end
