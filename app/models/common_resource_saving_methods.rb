module CommonResourceSavingMethods

  def create_instructor_resource_setting
    if visible_to_students?
      instructor_resource_settings = { user_id: user.id,
                                       student_visibility: 'shown' }
      resource.instructor_resource_settings.create(instructor_resource_settings)
    end
  end
  private :create_instructor_resource_setting

  def successful?
    successful
  end

  def save_successful
    upload_is_virus_free? && update_resource_attributes
  end

  def visible_to_students?
    params[:resource_student_visibility] == "true"
  end

  def uploaded_file_params
    process_uploaded_file(params[:uploaded_file]).merge({:uploaded_at => Time.now})
  end
  private :uploaded_file_params

  def unit_params
    unit_label
    case params[:unit_options]
      when "no_unit"
        resource_unit = Unit.resource_only_unit_for_program(params[:program_id])
        resource_unit_id = resource_unit.id unless resource_unit.blank?
        {"first_#{unit_label}".to_sym => resource_unit_id, "last_#{unit_label}".to_sym => nil}
      when "single_unit"
        {"last_#{unit_label}".to_sym => nil}
      when /lesson_id=(\d+)&start_unit_id=(\d+)$/
        match = params[:unit_options].match(/lesson_id=(\d+)&start_unit_id=(\d+)$/)
        { "first_#{unit_label}".to_sym => match[2],
          "lesson_id".to_sym => match[1],
          "last_#{unit_label}".to_sym => nil }
      else
        {}
    end
  end

  def unit_label
    @unit_label ||= get_unit_label
  end

  def get_unit_label
    resource_program = Program.find_by_id(params[:program_id])
    (resource_program && resource_program.unit_label.downcase) || 'unit'
  end

end
