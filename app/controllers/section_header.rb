# A module containing controller actions to handle displaying course name and whether a section is closed.
#
# Mix into any controller that is nested within sections
# requires a section_id param and a current_user
# assigns @section_header for use within course_name partial
#
module SectionHeader
  def assign_section_header
    @section_header = { :course_name => (current_section ?  current_section.course_name : 'No course'),
                        :closed => (current_section && current_section.closed?) }
  end
end
