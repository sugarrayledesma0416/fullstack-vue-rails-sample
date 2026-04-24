module SchoolHelper

  def format_school_label(school)
    region = school.state
    region = school.country_name unless school.country_name.blank?
    "#{school.name}, #{school.city}, #{region}"
  end

  def format_school_select(schools, course)
    schools.collect {|school| [school.name , school.id]}
  end

  def should_format_by_schools?(courses_by_school)
   courses_by_school.count > 1   
  end
end
