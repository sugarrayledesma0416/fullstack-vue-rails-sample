module Instructor::AssignablesHelper
  def show_icons_for_activity(assignable)
    output = ''

    if assignable.icon
      output << content_tag(
        :span,
        format_activity_icon(assignable.icon),
        class: 'icon'
      )
    end

    if assignable.instructor_graded?
      output << content_tag(:span, id: 'instructor_graded', class: 'icon') do
        image_tag('icon_person.png', title: 'instructor graded')
      end
    end

    output.html_safe
  end
end
