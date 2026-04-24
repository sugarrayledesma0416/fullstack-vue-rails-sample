module Jr
  class SectionsController < ::SectionsController
    layout 'music_v1/default'

    def show
      super
      # This view has a custom h1 header, so the normal @page_title
      # variable needs to be unset so the layout doesn't render an
      # extra h1. The @page_header var sets the <title> tag of the
      # page without setting the h1.
      @page_title = nil
      @page_header = 'Dashboard'
    end

    def study_schedule
      @menu_location = 'grownups'
      @sub_location = 'calendar'
      @calendar_presenter = build_calendar_presenter(params[:month])
      session[:activity_return] = {
        'label' => 'Return to Calendar',
        'url' => jr_section_study_schedule_path(section_id: current_section.id)
      }
    end

    private def assign_activity_return_to_url
      session[:activity_return] = {
        'label' => 'Return to Dashboard',
        'url' => jr_course_section_path(
          course_id: current_section.course_id,
          section_id: current_section.id
        )
      }
    end
  end
end
