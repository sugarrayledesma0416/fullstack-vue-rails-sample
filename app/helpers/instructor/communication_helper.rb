module Instructor::CommunicationHelper

  def format_communication_section_name(communication_item)
    if communication_item.new_record? && current_focus.focused_on_only_one_section?
      current_focus.section.name
    elsif communication_item.section
      communication_item.section.name
    else    
      "All sections"
    end    
  end

  def format_announcement_section_name(announcement)
    if current_focus.focused_on_only_one_section?
      current_focus.section.name
    else    
      "All sections"
    end    
    
  end

  
  def format_communication_course_name(communication_item)
    if communication_item.new_record?
      current_focus.course.name
    else
      communication_item.course.name    
    end    
  end 
end
