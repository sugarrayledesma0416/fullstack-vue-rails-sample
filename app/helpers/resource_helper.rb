module ResourceHelper
  include FileTypeParsable
  include ActionView::Helpers::TextHelper # needed for pluralize method

  def resource_index_link(path_args = {})
    program_path_args = path_args.merge(program_id: current_program.id)
    if supersite_junior?
      jr_resources_path(program_path_args.merge(section_id: current_section_id))
    else
      instructor_program_resources_path(program_path_args)
    end
  end

  def currently_applied_filters(url_params)
    ResourceRefinements.currently_applied_filters(url_params)
  end

  def error_message_for_protected_resources(resources)
    return '' if resources.blank?
    protected_resources = resources.select{|resource| resource.protected?}
    error_msg = ''
    unless protected_resources.empty?
      error_msg << "<div class=\"protected_resources_message\">Your changes were saved except for the following resource(s), which can never be shown to students:</div>"
      error_msg << "<ul class=\"protected_resources_list\">"
      protected_resources.each do |resource|
        error_msg << "<li>" << resource.title << "</li>"
      end
      error_msg << "</ul>"
    end
    error_msg
  end

  def error_message_for_failed_resources(resources)
    return '' if resources.blank?
    "<div class=\"protected_resources_message\">An error occurred while trying to update the selected resources.</div>"
  end

  private def current_unit?(unit_id, unit_type)
    if params[:lesson_id].present? && unit_type == 'lesson'
      params[:lesson_id] == unit_id.to_s
    elsif unit_type == 'unit'
      params[:start_unit_id] == unit_id.to_s
    end
  end

  def selected_unit_id(units)
    @selected_unit_id ||= units.first.id
  end

  def selected_lesson_id
    @selected_lesson_id ||= nil
  end

  # Collect the data needed to display the unit/lesson selector where the output
  # is an array of arrays where each inner array maps to an <option> in the
  # select.
  #
  # Example output (Lesson 1A is selected):
  # [["Unit 1", "/path/to/view?start_unit_id=21"]
  #  ["Lesson 1A", "/path/to/view?start_unit_id=21&lesson_id=22", '']
  #  ["Lesson 1B", "/path/to/view?start_unit_id=21&lesson_id=23"]]
  def units_filter_options(units)
    multi_lesson_ids = current_program.units.map(&:id).compact
    multi_lesson_params = multi_lesson_ids.inject('?') { |memo, id| memo << "start_unit_id[]=#{id}&" }

    units.inject([]) do |memo, unit|
      # First value: label
      if unit.display_name == 'No Lesson' || unit.display_name == 'No Unit'
        options = ['General Resources']
      else
        options = [unit.resources_form_display_name&.html_safe]
      end

      # Second value: path to filtered view
      # If a single unit, add the start_unit_id to the path.
      # Otherwise, add all lesson params found above.
      if unit.id.present?
        options << resource_index_link(start_unit_id: unit.id)
      else
        options << resource_index_link + multi_lesson_params
      end

      # Third value: html attributes (selected?, lang)
      html_attrs = { lang: lang_for(unit) }

      if params[:start_unit_id].is_a? Array
        html_attrs[:selected] = ''
        @selected_unit_id = params[:start_unit_id]
      elsif current_unit?(unit.id, 'unit')
        html_attrs[:selected] = ''
        @selected_unit_id = unit.id
      end

      options << html_attrs

      # If in a unit book, add the lessons.
      # Order must be Unit then lessons.
      if unit.lessons.size > 1
        all_options = [options]
        all_options.concat(lesson_filter_options(unit))
        memo.concat(all_options)
      else
        memo << options
      end
    end
  end

  private def lang_for(unit)
    if unit.resources_form_display_name.to_s.match?(/news and cultural updates/i)
      'en'
    else
      current_program.language_code
    end
  end

  private def lesson_filter_options(unit)
    unit.lessons.inject([]) do |memo, lesson|
      # First value: label
      options = [lesson.name&.html_safe]

      # Second value: path to filtered view
      options << resource_index_link(start_unit_id: unit.id, lesson_id: lesson.id)

      extra_attrs = { class: 'c-lesson-selector__lesson' }

      # Third value: selected?
      if current_unit?(lesson.id, 'lesson')
        extra_attrs[:selected] = ''
        @selected_lesson_id = lesson.id
        @selected_unit_id = unit.id
      end

      options << extra_attrs
      memo <<  options
    end
  end

  def formatted_resource_component_list(resource_components)
    resource_components.collect{ |rc| [rc.name.strip_tags, rc.id.to_s] }.sort
  end
end
