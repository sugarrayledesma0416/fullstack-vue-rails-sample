module Services
  class TocActivityList
    ACTIVITY_SCOPE_SELECT = <<~SQL.freeze
      activities.id, activities.concept_id, activities.activity_type,
      activities.lesson_id
    SQL

    def self.all_for_toc_location(toc_location, sections: nil, current_user: nil)
      # toc_location can either be a single value of an array of values.
      # We run .compact if it is an array to prevent returning all activities without a toc_location.
      toc_location = toc_location.compact if toc_location.is_a?(Array)
      if toc_location.present?
        filter_activity_scope(sections:, current_user:) do
          Activity.where(toc_location:)
        end
      else
        []
      end
    end

    def self.all_for_lesson(
      lessons,
      sections: nil,
      include_instructor_content: false,
      current_user: nil
    )
      filter_activity_scope(sections:, include_instructor_content:, current_user:) do
        Activity.where(lesson_id: lessons)
                .where.not(toc_location: nil)
      end
    end

    def self.all_for_program(
      program,
      sections: nil,
      include_instructor_content: false,
      current_user: nil
    )
      all_for_lesson(program.lessons, sections:, include_instructor_content:, current_user:)
    end

    def self.all_for_concept(concept, sections: nil,  current_user: nil)
      filter_activity_scope(sections:, current_user:) do
        Activity.where(concept_id: concept)
                .where.not(toc_location: nil)
      end
    end

    # We want to get all activities that are NOT assigned for any of the given sections.
    # It seems this method is not used, if it is, it might have a bug since it
    # removes the IGC activities with the condition 'AND activities.instructor_revision_id IS NULL'
    def self.all_unassigned_by_program(program_id, sections:, current_user:)
      lesson_scope = Lesson.joins(:unit).where(units: { program_id: })
      assignment_join = Activity.generate_unassigned_join(sections)
      # We want to exclude activities without toc_location because:
      # a) we can't get the strand when this column is null and
      # b) We can't assign activities that are not linked to a strand.
      # We also want to exclude instructor created activities because
      # they shouldn't be assignable.
      joined_scope = Activity.joins(:lesson).merge(lesson_scope)
                             .joins(assignment_join)
                             .includes(:concept, { lesson: :unit })

      filter_activity_scope(sections:, current_user:) do
        joined_scope.where(
          %(
            activities.component_name != 'unlisted'
            AND activities.toc_location IS NOT NULL
            AND assignments.id IS NULL
            AND activities.instructor_revision_id IS NULL
          )
        )
      end
    end

    def self.filter_activity_scope(
      sections:,
      include_instructor_content: false,
      current_user:
    )
      scoped_results = yield

      # If course set, we will have both activities and IGC, but, in the case of reports,
      # we don't have focus there, so, no course available. Therefore, we need a way to retrieve IGC activities
      # without breaking the fix made here to avoid student seeing IGC on TOC when they aren't enrolled into any course.

      if sections
        scoped_by_sections(scoped_results, sections:, include_instructor_content:, current_user:)
      elsif include_instructor_content
        scoped_results.pluck(:id)
      else
        scoped_results.where(activities: { instructor_revision_id: nil }).pluck(:id)
      end
    end
    private_class_method :filter_activity_scope

    def self.scoped_by_sections(
      activity_scope,
      sections:,
      include_instructor_content:,
      current_user:
    )
      sections = sections.compact
      # This is the main purpose of the Services::TocActivityList class.
      # The CourseLibraryActivity is used to return regular activities and
      # the instructor created activities with their visibility status.
      #
      # IMPORTANT: This system should be deprecated after there are no open courses
      # with CourseLibraryActivity records. With the implementation of the new IGC
      # share system, we stopped creating CourseLibraryActivity records.

      old_system_igs = activity_scope.select(ACTIVITY_SCOPE_SELECT)
                                     .joins(:course_library_activities)
                                     .merge(CourseLibraryActivity.by_course(sections.pluck(:course_id)))
                                     .where.not(activities: { instructor_revision_id: nil })
      # For the new IGC system.
      # If Section owner, InstitutionAdmin or DataAdmin:
      #   Show my IGCs for the program + co-instructors IGCs
      #
      # If Co-instructor:
      #   Show my IGCs for the program + owner IGCs + co-instructor IGCs if they are in the same section.
      #
      # If Student:
      #   Show all IGCs only if they are assigned.
      sections_instructors_user_ids = lambda do |sections_to_process|
        sections_to_process.flat_map { |section| section.instructors.pluck(:user_id) }
      end
      base_new_system_scope = activity_scope.select(ACTIVITY_SCOPE_SELECT)
                                            .where.not(activities: { instructor_revision_id: nil })
      new_system_igs = if current_user
                         case current_user.account_type
                         when 'Student'
                           base_new_system_scope.joins(:assignments).where(
                             assignments: { section_id: sections }
                           )
                         when 'InstitutionAdmin', 'DataAdmin'
                           base_new_system_scope.where(
                             activities: {
                               instructor_id: sections_instructors_user_ids.call(sections)
                             }
                           )
                         when 'Instructor'
                           # Course owner
                           if sections.any? { |section| section.instructor_id == current_user.id }
                             base_new_system_scope.where(
                               activities: {
                                 instructor_id: sections_instructors_user_ids.call(sections)
                               }
                             )
                           else
                             # Co-instructor
                             base_new_system_scope.where(
                               activities: {
                                 instructor_id: sections_instructors_user_ids.call(
                                   sections.select do |section|
                                     section.instructors.include? current_user
                                   end
                                 )
                               }
                             )
                           end
                         end
                       end || Activity.none
      regular_activities = activity_scope.select(ACTIVITY_SCOPE_SELECT)
                                         .where(activities: { instructor_revision_id: nil })

      (old_system_igs.pluck(:id) + new_system_igs.pluck(:id) + regular_activities.pluck(:id)).uniq
    end
    private_class_method :scoped_by_sections
  end
end
