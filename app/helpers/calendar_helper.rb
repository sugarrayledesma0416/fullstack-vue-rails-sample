module CalendarHelper
  def assessment_link_or_text(assessment_link_params, event_date = nil)
    if assessment_link_params.display_link?
      link_to(
        assessment_link_params.name,
        url_for(assessment_link_params.url_options),
        assessment_link_params.html_options.merge(
          'aria-label' => "#{assessment_link_params.name}, #{event_date}",
          'class' => 'u-txt-under'
        )
      )
    else
      content_tag(
        :span,
        assessment_link_params.name,
        assessment_link_params.html_options
      )
    end
  end

  def user_announcement_link(calendar_item, event_date = nil)
    label = pluralize_without_count(calendar_item.announcement_count, 'Announcement')

    link_to(
      "#{label}: #{calendar_item.announcement_count}",
      announcement_link_path(calendar_item),
      {
        'aria-label' => "#{label}, #{event_date}",
        class: 'u-txt-under'
      }
    )
  end

  def announcement_link_path(calendar_item)
    if current_user.instructor?
      instructor_announcements_path(current_program)
    elsif calendar_item.announcement_count == 1
      single_announcement_path(calendar_item.id)
    else
      multiple_announcement_path
    end
  end

  private def single_announcement_path(id)
    path_args = { id: id, section_id: current_section.id }

    if supersite_junior?
      jr_section_announcement_path(path_args)
    else
      section_announcement_path(path_args)
    end
  end

  private def multiple_announcement_path
    if supersite_junior?
      jr_section_grownups_path(section_id: current_section)
    else
      section_announcements_path(section_id: current_section)
    end
  end
end
