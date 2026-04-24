module Instructor::DashboardHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Context

  # This threshold is arbitrary and can be modified based on future requirements
  SECTION_AVERAGE_STUDENT_THRESHOLD = 50

  # turn an array of strings into a bulleted list
  def format_as_list(arr)
    tag.ul(class: 'c-list  u-mar-bot-0') do
      arr.map { |el| tag.li(el) }.join.html_safe
    end
  end

  def show_section_average?(student_count)
    student_count <= SECTION_AVERAGE_STUDENT_THRESHOLD
  end
end
