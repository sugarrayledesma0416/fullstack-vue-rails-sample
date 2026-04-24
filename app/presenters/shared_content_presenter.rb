class SharedContentPresenter < InstructorContentPresenter
  include MyContentPresentable

  private def shared_activities_by_toc_location
    @activities_by_toc_location ||= lesson_shared_activities.group_by(&:toc_location)
  end

  def shared_activities_by_toc_entry(toc_entry)
    shared_activities_by_toc_location[toc_entry.location.to_i] || []
  end

  def base_url(options = {})
    Rails.application.routes.url_helpers.instructor_shared_content_path(program.id, options)
  end

  def toc_path(*args)
    Rails.application.routes.url_helpers.instructor_shared_content_path(program.id, *args)
  end

  def shared_activity_creators
    @shared_activity_creators ||= fetch_activities.map do |activity|
      { full_name: activity.instructor_full_name, id: activity.instructor.id }
    end.uniq { |author| author[:id] }
  end

  private def fetch_activities
    @fetch_activities ||= InstructorCreatedActivity
                          .where(lesson_id: program.lessons)
                          .where(hide_from_my_content: false)
                          .where.not(instructor_id: current_user)
                          .joins(:shared_library_activities)
                          .where(shared_library_activities:
                          {
                            is_shared: true,
                            school: current_school
                          })
  end

  private def remove_as_shared_url(activity)
    Rails.application.routes.url_helpers
         .instructor_created_activities_remove_as_shared_path(
           instructor_created_activity_link_params(activity).merge(toc_location_params(activity))
         )
  end

  private def copy_to_mycontent_url(activity)
    Rails.application.routes.url_helpers
         .instructor_created_activities_copy_to_mycontent_path(
           instructor_shared_content_link_params(activity, program)
           .merge(toc_location_params(activity))
           .merge(page: search_page)
         )
  end

  private def instructor_shared_content_link_params(activity, program)
    { program_id: program.id, lesson_id: activity.lesson_id, toc_entry_id: activity.toc_location,
      id: activity.id, return_to: toc_path }
  end

  def remove_as_shared(activity)
    title = 'Remove as shared'
    msg = "Instructors will no longer be able to copy the shared activity: #{title}"

    link_to_unless(current_user.institution_admin?,
                   Music::Components.icon(variant: 'delete'),
                   '#',
                   class: 'is-disabled') do
      link_to(Music::Components.icon(variant: 'delete'),
              remove_as_shared_url(activity),
              title: title,
              data: { confirm: msg },
              method: :delete)
    end
  end

  def copy_to_mycontent(activity)
    link_to(copy_to_mycontent_url(activity), method: :put) do
      content_tag(:span) do
        '<music-icon-double-copy
          style="width: 25px; height: 25px;"
          size="lg"
          class="js-tooltip-auto"
          title="Copy to your content, then edit and assign your copy.">
        </music-icon-double-copy>'.html_safe
      end
    end
  end
end
