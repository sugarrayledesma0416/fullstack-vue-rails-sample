module MyContentPresentable

  # MAE-20872: it should always display every lesson, 
  # there should be no option to show or hide lessons relevant to a course
  # because my content is based on the instructor, not the course
  def visible_units
    program.units
  end
  private :visible_units

  def course_units_link
    nil
  end
end
