module Jr
  class ResourcesController < ::ResourcesController
    def index
      @page_title = nil
      @page_header = 'Resources'
      @menu_location = 'grownups'
      @sub_location = 'resources'
      @no_section_navigation = true

      @section = current_section
      assign_return_url
      render layout: 'layouts/music_v1/responsive'
    end
  end
end
