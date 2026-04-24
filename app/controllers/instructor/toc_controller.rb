class Instructor::TocController < RequireInstructorController
  include ReturnLink
  include HasHelp
  include LessonNavigable

  before_action :assign_menu_coords
  before_action :contextual_help_url

  def show
    @page_title = 'Activities'
    activities_toc_navigation_data = load_activities_toc_navigation_data.with_indifferent_access
    @presenter = InstructorTocPresenter.new(current_program,
                                            current_user,
                                            current_focus,
                                            activities_toc_navigation_data.merge(
                                              params.permit(
                                                :all_units,
                                                :display_lesson,
                                                :program_id,
                                                :section_id,
                                                :start_strand,
                                                :start_topic,
                                                :start_unit,
                                                :toc_location
                                              )
                                            ),
                                            session)
    if params.keys.include?('display_lesson')
      update_toc_lesson_navigation(
        activities_toc_data: params.slice(:display_lesson, :toc_location, :start_unit)
      )
    end

    @path_options = (path_options.presence || activities_toc_navigation_data)
    set_return_info('Return to Activities') do
      instructor_toc_path(current_program, path_options)
    end
  end

  private def assign_menu_coords
    @menu_location = 'content'
  end
end
