# Creates assignments for each given section.

class BulkAssignmentCreator
  attr_reader :sections, :course, :category_map, :source_section

  def initialize(sections, course, category_map, source_section)
    @sections = sections
    @course = course
    @category_map = category_map
    @source_section = source_section
  end

  def builder
    @assignment_builder ||= AssignmentBuilder.new
  end

  def categories
    @categories ||= builder.find_or_create_categories(course, category_map)
  end

  def activity_calendar(raw_assignments)
    builder.build_assignments(categories, raw_assignments)
  end

  def create(raw_assignments)
    Assignment.import(column_names, column_values(raw_assignments))
    add_igc_to_toc(raw_assignments)
    import_custom_order(raw_assignments)
    return unless @source_section && original_gchat_assignments(raw_assignments).present?

    create_gchat_assignment_configs
  end

  private def import_custom_order(raw_assignments)
    return unless @source_section

    src_assignment_sets = AssignmentSet.includes(:activities).where(section_id: @source_section.id)

    activity_calendar(raw_assignments).each do |assignment|
      find_or_create_assignment_sets(src_assignment_sets, assignment)
    end
  end

  private def find_or_create_assignment_sets(src_assignment_sets, assignment)
    src_assignment_sets.each do |src_assignment_set|
      src_assignment_set_activity = src_assignment_set.activities.find_by(
        activity_id: assignment[:activity_id]
      )

      if src_assignment_set_activity
        create_assignment_sets_for_sections(src_assignment_set_activity, assignment)
      end
    end
  end

  private def create_assignment_sets_for_sections(src_assignment_set_activity, assignment)
    sections.each do |destination_section|
      new_assignment_set = AssignmentSet.where(
        due_date: assignment[:due_date], section_id: destination_section.id
      ).first_or_create!
      new_assignment_set.activities.where(
        activity_id: assignment[:activity_id]
      ).first_or_create!(
        activity_id: assignment[:activity_id],
        assignment_set_rank: src_assignment_set_activity.assignment_set_rank
      )
    end
  end

  private def add_igc_to_toc(raw_assignments)
    activity_calendar(raw_assignments).each do |assignment|
      next unless assignment[:is_igc]

      course_library_activity = add_course_library_activity(@course.is_template, assignment)
      reconcile_assignment_with_share_library(
        @course.school_id,
        assignment,
        course_library_activity
      )
    end
  end

  # This is to cover an edge case, that occurs when:
  # 1. The instructor has a course that was not created from a template, and
  #   has a section with an assignments that points to an IGC activity that the
  #   instructor has shared with the school. Let's call the section Section_A
  # 2. He creates a template course, but doesn't inherint assignments from any other course
  #    while creating the course.
  # 3. He creates a template section for the template course.
  # 4. After creating the template section, the instructor goes to the assignment wizard
  #    for that section and copies the assignments from Section_A, which will include the
  #    assignment for the IGC the instructor shared.
  # The assignment created for the section template, points to the original version
  # of the IGC and not the copy that is created during the share process.
  # This method corrects that unexpected behavior by updating the assignment and the
  # CourseLibraryActivity record, to point to the correct activity that is in the
  # shared library.
  private def reconcile_assignment_with_share_library(school_id, assignment, course_library_activity)
    assignments_to_update = Assignment.where(
      assignable_id: assignment[:activity_id],
      section: @sections
    )
    shared_library_activity = SharedLibraryActivity.where(
      source_activity_id: assignment[:activity_id],
      school_id:
    ).first
    if shared_library_activity && assignments_to_update.present?
      Assignment.transaction do
        assignments_to_update.each do |assignment_to_update|
          assignment_to_update.update!(assignable_id: shared_library_activity.activity_id)
        end
        # We use update_attribute, since the Course default scope filters out template courses,
        # causing a 'Course must exist' error.
        # rubocop:disable Rails/SkipsModelValidations
        course_library_activity.update_attribute(
          :activity_id,
          shared_library_activity.activity_id
        )
        # rubocop:enable Rails/SkipsModelValidations
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    # We don't bubble up the exception. There can be a lot of assignments being
    # processes in bulk and we don't want to stop the assignments creation for
    # not updating the data on this edge case.
    VHLMonitor.notify(e)
  end

  private def add_course_library_activity(is_template, assignment)
    if is_template
      find_or_create_template_course_library_activity(assignment)
    else
      find_or_create_course_library_activity(assignment)
    end
  end

  private def find_or_create_template_course_library_activity(assignment)
    # This is needed because Course's default scope filters out templates,
    # causing existing records to not be found & saving to fail validation
    # via this class's assocation with Course.
    Course.unscoped do
      CourseLibraryActivity.where(
        course_id: @course.id,
        activity_id: assignment[:activity_id]
      ).first_or_create(hidden: false)
    end
  end

  private def find_or_create_course_library_activity(assignment)
    CourseLibraryActivity.where(
      course_id: @course.id,
      activity_id: assignment[:activity_id]
    ).first_or_create(hidden: false)
  end

  private def create_gchat_assignment_configs
    @sections.each do |destination_section|
      gchat_assignment_config_creater = BulkGchatAssignmentConfigCreator.new(
        @original_gchat_assignments,
        destination_section.id
      )
      gchat_assignment_config_creater.create
    end
  end

  private def column_names
    [
      :assignable_type,
      :due_date,
      :section_id,
      :assignable_id,
      :category_id,
      :rank,
      :individually_assignable
    ]
  end

  private def column_values(raw_assignments)
    activity_calendar(raw_assignments).map do |assignment|
      sections.map do |section|
        assignment_attributes(assignment, section)
      end
    end.flatten(1)
  end

  private def activity_ids_from(raw_assignments)
    builder.activity_ids_from(raw_assignments)
  end

  private def assignment_attributes(assignment, section)
    [
      'Activity',
      Date.parse(assignment[:due_date]),
      section.id,
      assignment[:activity_id],
      assignment[:category].id,
      assignment[:rank],
      assignment[:individually_assignable]
    ]
  end

  private def original_gchat_assignments(raw_assignments)
    @original_gchat_assignments = @source_section.assignments
                                  .where(assignable_id: activity_ids_from(raw_assignments))
                                  .select(
                                    'assignments.*, gcac.group_maximum, gcac.group_minimum'
                                  ).joins(
                                    'INNER JOIN group_chat_assignment_configs ' \
                                    'gcac ON gcac.assignment_id = assignments.id'
                                  )
  end
end
