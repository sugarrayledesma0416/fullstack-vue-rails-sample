class ResourcesPresenter
  include ResourceVisibility
  include Rails.application.routes.url_helpers

  attr_accessor :user, :section, :program, :opts

  delegate :unit_label, to: :program, allow_nil: true

  def initialize(user, section, program, opts)
    self.user    = user
    self.section = section
    self.program = program
    self.opts    = opts

    # default to showing only the resources for the first unit
    unless opts[:start_unit_id].present?
      opts[:start_unit_id] = units.first.id
    end
  end

  def finder
    @finder ||= Resource.find_all_for_user_and_section(program, user, opts, section)
  end

  def resources
    @resources ||= finder.all_sorted_by_unit_rank
  end

  # Set the end_unit_id to -1 if there isn't one so the sort doesn't break.
  # Sort by end_unit_id first then start_unit_id so the multi-unit resources
  # are at the bottom of the list and in order by start_unit_id.
  def sorted_resources
    resources.sort_by do |r|
      r.end_unit_id = r.end_unit_id || -1
      [r.end_unit_id, r.start_unit_id]
    end
  end

  def program_unit_label
    unit_label.blank? ? 'Unit' : unit_label
  end

  def filter_results?
    browse_or_search_keys.any? { |key| opts[key].present? }
  end

  def browse_or_search_keys
    [:start_unit_id, :component_id, :lesson_id, :search_string]
  end
  private :browse_or_search_keys

  def units
    return @units if defined?(@units)
    @units = program.visible_units_and_resource_units(user.can_view_unreleased_units?).to_a
    @units << Unit.new(:program => program, :name => program.multi_unit_resource_label)
  end

  def lessons
    if program.two_tier?
      program.visible_lessons(user.can_view_unreleased_units?)
    end
  end

  def components
    @components ||= ResourceComponent.components_by_program(program)

    # Filter out the components that have no visible resources from student view
    unless user.instructor?
      @components = @components.select do |component|
        component_exists?(component)
      end
    end
    @components
  end

  def sorted_components
    components.sort do |component_a, component_b|
      component_a.name <=> component_b.name
    end
  end

  def resource_refinements
    @resource_refinements ||= ResourceRefinements.new(
      finder,
      program,
      opts.merge(can_see_unreleased_units: user.can_view_unreleased_units?)
    )
  end

  def resource_components
    unit_only_opts = opts.except(:component_id)
    # This line doesn't seem to do anything, but that doesn't seem to cause
    # any problems.
    unit_only_opts.merge(can_see_unreleased_units: user.can_view_unreleased_units?)
    units_finder = Resource.find_all_for_user_and_section(
      program, user, unit_only_opts, section
    )
    @resource_components ||= ResourceRefinements.new(
      units_finder, program, unit_only_opts
    )
  end

  def resources_header
    if filter_results?
      resource_refinements.refinements_description
    else
      'Browse Resources'
    end
  end

  def resource_count(component)
    resource_components.category_options("components")[component.name][:count]
  end

  def component_exists?(component)
    !resource_components.category_options("components")[component.name].blank?
  end

  def filtered_components
    resource_refinements.category_options("components")
  end

  def all_components_selected?
    opts[:component_id].blank?
  end

  def component_selected?(component)
    !all_components_selected? && filtered_components[component.name].present?
  end

  def reset_url
    if user.instructor?
      instructor_program_resources_path(program)
    else
      resources_path(program, section)
    end
  end

  def instructor_resource_settings
    @instructor_resource_settings ||= InstructorResourceSetting.where(
      resource_id: resources.ids, user_id: user.id
    )
  end

  def resource_status_for(resource)
    if resource.protected?
      'protected'
    else
      student_resource_viewable?(resource, settings_for(resource.id), user) ? 'shown' : 'hidden'
    end
  end

  def settings_for(resource_id)
    # A resource could have multiple visibility setting - one per instructor -
    # so we need to retrieve the one belonging to the instructor who's navigating thru
    # resources page.
    instructor_resource_settings.detect { |irs| irs.resource_id == resource_id && irs.user_id == user.id }
  end
  private :settings_for

  def units_dropdown_label
    if program.lesson_label.present?
      "by #{program.lesson_label}"
    else
      'Browse by Lesson'
    end
  end

  def component_display_name(component)
    "#{component.name.html_safe} (#{resource_count(component)})"
  end

  def filter_by_component?
    opts[:component_id].present?
  end

  def filter_by_lesson?
    opts[:lesson_id].present?
  end

  # Format the lesson number for the table
  # Returns either a single digit or a range.
  def lesson_number(resource)
    start_unit_label = resource.location_name_for_unit(resource.start_unit_id)
    end_unit_label = resource.location_name_for_unit(resource.end_unit_id)
    start_unit_number = start_unit_label.split(' ').last

    # If there is no end unit, return only the start unit number
    # Otherwise return a range: start - end
    if end_unit_label.blank?
      start_unit_number
    else
      end_unit_number = end_unit_label.split(' ').last
      "#{start_unit_number} - #{end_unit_number}"
    end
  end

  def unit_title(unit, resource)
    unit.resources_form_title.present? ? unit.resources_form_title :
      has_units_with_blank_label?(resource) ? unit.name : unit.label
  end

  def has_units_with_blank_label?(resource)
    labels = resource.program.units.pluck(:label)
    labels.any?(&:blank?)
  end

  def resource_description(resource)
    return 'No Description' if resource.description.blank?
    resource.description.to_s.html_safe
  end
end
