class CourseOptions
  include ActiveModel::Serialization

  attr_reader :instructor, :course, :program
  attr_accessor :selected_school_id

  delegate(
    :setup_descriptions,
    :supported_standard_sets,
    :supported_standard_set_ids,
    to: :program_config
  )
  delegate(
    :one_roster_linked?,
    :has_one_roster_academic_session?,
    :autorostering_linked?,
    :lti_roster_linked?,
    :any_due_dates_reached?,
    :assignments?,
    to: :course,
    allow_nil: true
  )

  def initialize(instructor, course, program, selected_school_id = nil)
    @instructor = instructor
    @course = course
    @program = program
    self.selected_school_id = selected_school_id
  end

  def units
    program.units
  end

  # NOTE: This includes all "level" course packages for the associated program,
  # regardless of license context.
  def levels
    course_packages['level'] || []
  end

  # NOTE: This includes all "component" course packages for the associated program,
  # regardless of license context.
  def components
    course_packages['component'] || []
  end

  def video_languages
    @video_languages ||= course.possible_video_languages.inject({}) do |hash, language|
      hash[language[0]] = language[1]
      hash
    end
  end

  def basic_category
    @basic_category ||= {
      name: 'Homework',
      weighting_percent: 100,
      credit_only: false,
      max_attempts: 2,
      enhanced_feedback_disabled: false,
      accept_late_work: true,
      late_work_penalty: 'percent_per_day',
      penalty_percent: 5,
      rank: 1,
      scoring_rulesets_attributes: [ScoringRuleset.new_course_defaults]
    }
  end

  private def default_course_attributes
    @default_course_attributes ||= {
      allow_individual_assign: true,
      school_id: default_school.id,
      first_unit: program.units.first,
      last_unit: program.units.last,
      end_date: 14.weeks.from_now,
      start_date: Time.zone.now
    }
  end

  def default_courses
    @default_courses ||= [
      {
        name: 'Default settings'
      }, {
        name: 'Basic course',
        categories_attributes: [basic_category]
      }
    ].map do |attrs|
      Course.new(default_course_attributes.merge(attrs))
    end
  end

  def previous_courses
    return @previous_courses if defined?(@previous_courses)

    instructor_non_template_courses = Course.by_program(program)
                                            .where(section_instructors: { user_id: instructor.id })
                                            .joins(sections: :section_instructors)
                                            .pluck(:id)

    @previous_courses = courses_sorted_with_sections_and_categories(
      Course,
      instructor_non_template_courses
    )
  end

  def previous_course_templates
    return @previous_course_templates if defined?(@previous_course_templates)

    # Return sensible default if no selected school id.
    return @previous_course_templates = [] unless selected_school_id

    instructor_template_courses = Course.templates
                                        .by_program(program)
                                        .by_school(School.find(selected_school_id))
                                        .pluck(:id)

    @previous_course_templates = courses_sorted_with_sections_and_categories(
      Course.templates,
      instructor_template_courses
    )
  end

  def previous_courses_with_assignments
    @previous_courses_with_assignments ||= (previous_sections_with_assignments |
                                           previous_sections_with_external_items)
                                           .map(&:course)
                                           .uniq
                                           .reject{ |course| course.is_template }
                                           .sort_by do |course|
                                             [course.start_date, course.name]
                                           end
  end

  def previous_enterprise_courses_with_assignments
    enterprise_courses = Course.enterprise
                               .by_program(program)
                               .where.not(id: @course.id)
                               .where(school_id: @course.school_id)

    enterprise_courses_with_assignments = enterprise_courses.select do |course|
      enterprise_section = course.enterprise_section
      enterprise_section && (
        enterprise_section.assignments.exists? ||
          GradebookEngine::GradebookAPI.find_external_items_by_section(enterprise_section.id).any?
      )
    end

    enterprise_courses_with_assignments.sort_by do |course|
      [course.start_date, course.name]
    end
  end

  def previous_course_templates_with_assignments
    @previous_course_templates_with_assignments ||= (previous_sections_with_assignments |
                                                    previous_sections_with_external_items)
                                                    .map(&:course)
                                                    .uniq
                                                    .filter(&:is_template)
                                                    .sort_by do |course|
                                                      [course.start_date, course.name]
                                                    end
  end

  def sections_for_course(course_id)
    @sections_for_course_map ||= (
      previous_sections_with_assignments | previous_sections_with_external_items
    ).group_by { |section| section.course.id }
    @sections_for_course_map.fetch(course_id, []).sort_by(&:name)
  end

  private def previous_sections_with_assignments
    # Retrieves sections in this program that have assignments and are
    # owned, co-instructed or assisted by the instructor

    @previous_sections_with_assignments ||=
      instructor.sections.joins(:course, :section_instructors)
                .merge(SectionInstructor.responsible)
                .where(
                  courses: { program_id: program }
                ).group('sections.id').select do |section|
                  section.assignments.count.positive?
                end
  end

  private def previous_sections_with_external_items
    # Retrieves sections in this program that have external items and are
    # owned, co-instructed or assisted by the instructor

    @previous_sections_with_external_items ||=
      instructor.sections.joins(:course, :section_instructors)
                .merge(SectionInstructor.responsible)
                .where(
                  courses: { program_id: program }
                ).group('sections.id').select do |section|
                  GradebookEngine::GradebookAPI.find_external_items_by_section(
                    section.id
                  ).size.positive?
                end
  end

  def preview_sections_by_school
    @preview_sections_by_school ||= instructor.schools.inject({}) do |hash, school|
      hash[school.id] = [preview_section] + existing_sections[school.id]
      hash
    end
  end

  def course_packages_by_course
    return @course_packages_by_course if defined?(@course_packages_by_course)

    courses = (course.guid && course.id) ? { course.guid => course.id } : {}
    previous_courses.map { |course| courses[course.guid] = course.id }

    course_packages = Maestro::CoursePackage.all_for_courses(courses.keys)
    # Group course packages by course id and content type.
    @course_packages_by_course = courses.each_with_object({}) do |(course_guid, course_id), memo|
      memo[course_id] = course_packages[course_guid].group_by(&:content_type)
    end
  end

 private def program_config
    @program_config ||= ProgramConfig.currently_active(program)
  end

  private def preview_section
    @preview_section ||= Section.new(instructor: instructor,
                                     instructors: [instructor],
                                     course: course)
  end

  private def existing_sections
    @existing_sections ||= instructor.sections_grouped_by_school_id(program)
  end

  # Returns all course packages for the current program grouped by their content type.
  #
  # NOTE: This includes all course packages for the program, not just those
  # available for the current school through site licensing.
  #
  # @return [Hash{String => Array<Maestro::CoursePackage>}] a hash where the keys
  #   are content types and the values are arrays of course packages.
  private def course_packages
    @course_packages ||= Maestro::CoursePackage.all(program.id).group_by(&:content_type)
  end

  # Returns a hash representing course packages available for the current
  # program under the associated school/district site licenses.
  #
  # @return [Array<Hash>, nil] An array of hashes representing available course
  #   packages or nil if none are available. See specs for sample hash structure.
  def available_course_packages
    course_packages = Maestro::CoursePackage
      .available_packages(program.id,
                          default_school.guid,
                          default_school.find_district_guid)
    if course_packages.any?
      course_packages
    else
      nil
    end
  end

  # Returns a unique array of available course package IDs.
  #
  # @return [Array<Integer>] an array of unique course package IDs or an empty
  #   array if none are available.
  # TODO: Remove `uniq` call once query is fixed.
  def available_course_package_ids
    available_course_packages&.map { |hash| hash['id'] }&.uniq || []
  end

  private def default_school
    @default_school ||= School.find(selected_school_id || instructor.most_recent_school_id)
  end

  def categories_with_assessment_count_for_course(course_obj)
    @categories_with_assessment_count_for_course ||= Category.with_assessment_count(previous_courses.map(&:id)).group_by(&:course_id)
    @categories_with_assessment_count_for_course[course_obj.id] || []
  end

  def scoring_ruleset_by_id(scoring_ruleset_id)
    @scoring_rulesets_by_id ||= previous_scoring_rulesets.index_by(&:id)
    @scoring_rulesets_by_id[scoring_ruleset_id] || default_scoring_ruleset
  end

  private def previous_scoring_rulesets
    ScoringRuleset.joins(:category).where(
      categories: { course_id: previous_course_and_template_ids }
    )
  end

  private def previous_course_and_template_ids
    previous_course_templates.pluck(:id) + all_previous_courses.pluck(:id)
  end

  private def all_previous_courses
    instructor.editable_courses_by_program(program)
  end

  private def default_scoring_ruleset
    @default_scoring_ruleset ||= ScoringRuleset.default.dup
  end

  def previous_course_templates_and_section_data
    courses_with_assignments = previous_course_templates_with_assignments
    courses_with_assignments.uniq(&:id).map do |course|
      CourseWithSectionBuilder.new(course, self).build
    end
  end

  def previous_course_and_section_data(is_enterprise = false)
    courses_with_assignments = previous_courses_with_assignments

    if is_enterprise
      courses_with_assignments += previous_enterprise_courses_with_assignments
      courses_with_assignments += previous_course_templates_with_assignments
    end

    courses_with_assignments.uniq(&:id).map do |course|
      CourseWithSectionBuilder.new(course, self).build
    end
  end

  private def courses_sorted_with_sections_and_categories(scope, ids)
    # TODO: When we upgrade to Rails 5, we'll need to add `joins` on sections and categories
    #       for eager loading to work. Note that the joins may need to be left joins in case there
    #       there aren't related records on the right side of the join.
    scope.includes([{ sections: { section_instructors: :instructor } }, :categories])
         .order('start_date ASC, courses.name ASC')
         .find(ids)
  end
end
