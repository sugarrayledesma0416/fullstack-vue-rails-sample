module Jr
  class LessonsController < ApplicationController
    before_action :require_user

    layout 'music_v1/default'

    def index
      @menu_location = 'content'
      @page_title = 'Activities'
    end

    def show
      @menu_location = 'content'

      # Query like this so someone can't hack the URL and display a lesson for
      # a program in which they're not enrolled.
      @lesson = current_program.lessons.find_by!(id: params[:id])

      # TechProd may have used html tags in the lesson name. Since the
      # @page_title variable populates the contents of the <title> tag,
      # that html should be stripped out.
      @page_title = @lesson.name.strip_tags
    end
  end
end
