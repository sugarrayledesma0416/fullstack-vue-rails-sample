class CourseOptionsSerializer < ActiveModel::Serializer
  attributes :units, :levels, :components, :settings, :video_languages, :setup_descriptions,
             :program, :course, :schools, :previous_courses, :available_course_packages,
             :selected_school_id, :has_one_roster_academic_session, :one_roster_linked,
             :has_one_roster_academic_session, :template_settings, :previous_course_templates,
             :autorostering_linked, :lti_roster_linked, :allow_copy, :assignments,
             :supported_standard_sets, :ai_virtual_chat_level

  def schools
    instructor_schools.map do |school|
      {
        id: school.id,
        name: school.name
      }
    end
  end

  def course
    course_data = course_attributes(object.course)
    course_data[:course_owner_user_id] = object.course.owner_id
    course_data
  end

  def program
    {
      id: object.program.id,
      lesson_label: object.program.lesson_label,
      unit_label: object.program.unit_label
    }
  end

  def units
    object.units.map do |unit|
      filter_hash(unit.attributes.merge('label' => unit.display_name), ['id', 'label'])
    end
  end

  def levels
    object.levels.map do |level|
      course_package_attributes(level)
    end
  end

  def components
    object.components.map do |component|
      course_package_attributes(component)
    end
  end

  def video_languages
    object.video_languages.inject({}) do |hash, language|
      label, value = language
      hash[label] = value
      hash
    end
  end

  def settings
    (object.default_courses + object.previous_courses).map do |course|
      course_attributes(course)
    end
  end

  def template_settings
    object.previous_course_templates.map { |template| course_attributes(template) }
  end

  def ai_virtual_chat_level
    object.course.ai_virtual_chat_level
  end

  def previous_courses
    object.previous_course_and_section_data
  end

  def previous_course_templates
    object.previous_course_templates_and_section_data
  end

  def lti_roster_linked
    object.lti_roster_linked?
  end

  def one_roster_linked
    object.one_roster_linked?
  end

  def autorostering_linked
    object.autorostering_linked?
  end

  def allow_copy
    object.lti_roster_linked? && !object.any_due_dates_reached?
  end

  def assignments
    object.assignments?
  end

  def has_one_roster_academic_session
    object.has_one_roster_academic_session?
  end

  # Returns the supported standard sets grouped by their display name
  def supported_standard_sets
    object.supported_standard_sets.group_by do |standard_set|
      standard_set.display_name.presence || "#{standard_set.issuer} - #{standard_set.name}"
    end.map do |name, standard_sets|
      {
        name:,
        ids: standard_sets.map(&:id)
      }
    end
  end

  private def course_package_attributes(package)
    filter_hash(package.response, ['id', 'name', 'course_package_contents', 'license_groups'])
  end

  private def filter_hash(hash, keys)
    hash.select do |k, _|
      keys.include?(k)
    end
  end

  private def instructor_schools
    object.instructor.schools.reject { |school| school.district? }
  end

  private def course_attributes(course)
    CourseAttributesSerializer.new(object, course).to_hash
  end

  # This class is used to serialize all the attributes of a specified course.
  # It's used to serialize course attributes, course template attributes, default
  # courses attributes and previous courses attributes.
  class CourseAttributesSerializer
    include DateTimeHelper

    attr_accessor :course, :course_options

    def initialize(course_options, course)
      self.course_options = course_options
      self.course = course
    end

    def to_hash
      {
        ai_virtual_chat_level: course.ai_virtual_chat_level,
        allow_audio_transcripts: course.allow_audio_transcripts,
        allow_individual_assign: course.allow_individual_assign,
        allow_video_popup_translation: course.allow_video_popup_translation,
        portfolio_activity_types: course.portfolio_activity_types,
        allows_help_requests: course.allows_help_requests,
        allows_review_requests: course.allows_review_requests,
        can_share_to_portfolio:,
        categories: course.categories.map { |category| category_attributes(category) },
        chat_level: course.chat_level,
        class_days: class_days,
        components: course_component_ids,
        display_on_dashboard: !course.hide_from_instructor_dashboard,
        enable_vocab_tutorial_translations: course.enable_vocab_tutorial_translations,
        end_date: safe_date_string(course.end_date),
        first_unit_id: course.first_unit_id,
        id: course.id,
        is_template: course.is_template,
        last_unit_id: course.last_unit_id,
        level: course_level_id,
        name: course.name,
        school_id: course.school_id,
        sections: previous_sections,
        share_to_google_classroom: course.share_to_google_classroom,
        share_to_portfolio: course.share_to_portfolio,
        show_estimated_times: course.show_estimated_times,
        start_date: safe_date_string(course.start_date),
        standard_set_ids: standard_set_ids,
        video_subtitle_languages: course.video_subtitle_languages,
        video_transcript_languages: course.video_transcript_languages
      }
    end

    private def standard_set_ids
      if course.persisted?
        course.standard_set_ids
      else
        # For a new course, returns all the standard sets supported by the program
        course_options.supported_standard_set_ids
      end
    end

    private def can_share_to_portfolio
      if course.persisted?
        course.program_share_to_portfolio?
      else
        # For a new course, returns the portfolio settings of selected
        # school and program
        course_options.course&.program_share_to_portfolio?
      end
    end

    private def category_attributes(category)
      {
        id: category.id,
        name: category.name,
        weighting_percent: category.weighting_percent,
        has_assessment_assignments: has_assessments?(category),
        has_assignments: category.has_assignments?,
        credit_only: category.credit_only,
        max_attempts: category.max_attempts,
        enhanced_feedback_disabled: category.enhanced_feedback_disabled,
        accept_late_work: category.accept_late_work,
        late_work_penalty: category.late_work_penalty,
        penalty_percent: category.penalty_percent,
        rank: category.rank,
        drop_low_scores: category.drop_low_scores,
        current_scoring_ruleset: scoring_ruleset_attributes(
          course_options.scoring_ruleset_by_id(category.current_scoring_ruleset_id)
        )
      }
    end

    private def has_assessments?(category)
      if assessment_count_by_category_id[category.id]
        assessment_count_by_category_id[category.id] > 0
      else
        false
      end
    end

    private def scoring_ruleset_attributes(scoring_ruleset)
      {
        id: scoring_ruleset.id,
        ignore_capitalization: scoring_ruleset.ignore_capitalization,
        ignore_punctuation: scoring_ruleset.ignore_punctuation,
        ignore_accents: scoring_ruleset.ignore_accents
      }
    end

    private def assessment_count_by_category_id
      return @assessment_count_by_category_id if defined? @assessment_count_by_category_id

      categories_with_counts = course_options.categories_with_assessment_count_for_course(course)
      # Build hash that maps course ids to number of assessments.
      # Categories without assignments are not included in the hash, but categories
      # with assignments but without assessments are included.
      @assessment_count_by_category_id = Hash[
        categories_with_counts.map { |c| [c.id, c.assessment_count] }
      ]
    end

    private def class_days
      enterprise_section = course.enterprise_section
      if enterprise_section.present?
        enterprise_section.class_days
      end
    end

    private def previous_sections
      course.sections.present? && course.sections.map do |section|
        {
          id: section.id,
          name: section.name,
          section_instructors: section_instructors_info(section.section_instructors),
          additional_info: section.additional_info,
          hide_owner_name: section.hide_owner_name
        }
      end
    end

    private def section_instructors_info(section_instructors)
      section_instructors.map do |si|
        {
          full_name: si.instructor.full_name,
          role: si.role,
          first_name: si.instructor.first_name,
          last_name: si.instructor.last_name
        }
      end
    end

    private def course_component_ids
      packages = course_options.course_packages_by_course[course.id]
      components = (packages && packages['component']) || []
      components.map(&:id)
    end

    private def course_level_id
      packages = course_options.course_packages_by_course[course.id]
      level = packages && packages['level'] && packages['level'].first
      level.id if level
    end
  end
end
