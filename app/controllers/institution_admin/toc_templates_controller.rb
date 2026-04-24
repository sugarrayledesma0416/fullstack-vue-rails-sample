class InstitutionAdmin::TocTemplatesController < Instructor::TocController
  include TemplateFocusable
  include LessonNavigable

  before_action :show_templates_return_bar

  def show
    @page_title = 'Activities'
    activities_toc_navigation_data = load_activities_toc_navigation_data.with_indifferent_access
    @presenter = InstitutionAdminTocPresenter.new(@program,
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
      institution_admin_show_toc_template_path(current_program, path_options)
    end
  end
end
