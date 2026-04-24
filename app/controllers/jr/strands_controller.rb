module Jr
  class StrandsController < ApplicationController
    before_action :require_user
    before_action :assign_activity_return_to_url

    layout 'music_v1/default'

    def show
      @menu_location = 'content'
      # Query like this so someone can't hack the URL and display a strand for
      # a program in which they're not enrolled.
      @concept = current_program.concepts.find_by!(id: params[:id])
      @lesson = @concept.lesson
      @strand = @lesson.strand(@concept.id)

      # TechProd is allowed to use html tags in strand names. Since the
      # @page_title variable populates the contents of the <title> tag,
      # that html should be stripped out.
      @page_title = "#{@lesson.display_name} | #{@strand.title}".strip_tags.html_decode
      assign_presenter
    end

    private def assign_activity_return_to_url
      session[:activity_return] = {
        'label' => 'Return to Activities',
        'url' => request.fullpath
      }
    end

    private def assign_presenter
      @presenter = TocPresenter.new(
        lesson: @lesson,
        program: current_program,
        section: current_section,
        strand: @strand,
        user: current_user
      )
    end
  end
end
