module EnrollmentHelper
  include ActionView::Helpers::TextHelper

  def selected_section(sections,selected_section)
    return selected_section.id if selected_section
    return sections.first.id if sections.count == 1
    ""
  end

  def mark_checked(obj,ids_array)
    return false unless ids_array
    return false if ids_array.empty?
    return false unless ids_array.include?(obj.id.to_s)
    true
  end

end
