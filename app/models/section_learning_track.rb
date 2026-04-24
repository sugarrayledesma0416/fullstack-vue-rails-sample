# A custom learning track can be created from an existing section's
# assignments and course packages.
class SectionLearningTrack
  include AssignmentSorter
  include SectionLearningTrackAssignable

  DEFAULT_LICENSE_GROUP_IDS = [21].freeze

  include ActiveModel::Serialization

  attr_reader :section, :course_packages, :current_course_id

  def initialize(section, course_packages, current_course_id)
    @section = section
    @course_packages = course_packages
    @current_course_id = current_course_id
  end

  def course_package_ids
    @course_package_ids ||= course_packages.map(&:id)
  end

  def description
    course = @section.course
    weeks_and_days_data = CourseTimeCalculator.formatted_time(course)
    "#{course.name} (#{weeks_and_days_data[:weeks]})"
  end

  def categories
    @categories ||= section.categories.each_with_object({}) do |category, memo|
      memo[category.name] = category
    end
  end

  def strands
    @strands ||= assigned_concepts_by_id.values.map(&:base_name).uniq
  end

  def units
    @units ||= licensed_activities
               .map(&:lesson)
               .map(&:unit)
               .concat(external_activity_units)
               .uniq.sort_by(&:rank)
  end

  def first_unit_id
    units.first.try(:id)
  end

  def last_unit_id
    units.last.try(:id)
  end

  def license_group_ids
    # Express
    return DEFAULT_LICENSE_GROUP_IDS unless current_course_id

    # Get license group ids for the course
    current_course_guid = Course.unscoped.find_guid(current_course_id)
    @license_group_ids ||= Maestro::CourseLicense.all(current_course_guid).map do |course_license|
      course_license.license_group.id
    end
  end

  def insufficient_license_groups
    licensed_assignments.size < assignments.size
  end

  private def external_activity_units
    external_items = GradebookEngine::GradebookAPI.find_external_items_by_section(@section.id)
    return [] unless external_items.any?

    unit_ids = external_items.map(&:lesson).map(&:unit_id)
    Unit.find(unit_ids)
  end

  private def assigned_concepts_by_id
    @assigned_concepts_by_id ||= licensed_activities.map(&:concept).index_by(&:id)
  end

  private def licensed_activities
    @licensed_activities ||= licensed_assignments.map(&:assignable)
  end

  private def licensed_assignments
    @licensed_assignments ||= assignments.select do |assignment|
      licensed_activity?(assignment.assignable)
    end
  end

  private def licensed_activity?(activity)
    license_group_ids
      .include?(activity.license_group_id) || activity.lesson.unit.use_type == 'CurrentEvents'
  end

  private def licensed_assignment?(license_group_id, unit)
    license_group_ids.include?(license_group_id) || unit.use_type == 'CurrentEvents'
  end

  private def assignments
    return @assignments if defined?(@assignments)

    assignment_scope = section.assignments
                              .by_type(Activity)
                              .where('activities.toc_location is not null')
                              .includes(:category,
                                        :track_group,
                                        assignable: [:concept, { lesson: :unit }])
    @assignments = sort_by_due_date_and_rank(assignment_scope)
  end
end
