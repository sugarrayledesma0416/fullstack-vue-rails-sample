module Enterprise
  class CourseUpdater
    def initialize(course, update_params)
      @course = course
      @params = update_params
    end

    def update
      return @course unless course_valid? && course_owner_valid?

      @course.transaction do
        @course.save!
        course_owner_updater.update

        if @course.enterprise_section.saved_change_to_attribute?('class_days')
          update_sections_class_days
        end
      end

      @course
    end

    private def course_valid?
      unless @course.is_enterprise?
        @course.errors.add(:base, 'Course must be enterprise')

        return false
      end

      @course.assign_attributes(@params)

      @course.valid?
    end

    private def course_owner_valid?
      if course_owner_updater.to_update? && !course_owner_updater.valid?
        course_owner_updater.errors.each do |error_message|
          @course.errors.add(:base, error_message)
        end

        return false
      end

      true
    end

    private def course_owner_updater
      @course_owner_updater ||= begin
        new_owner = @course.owner
        previous_owner =
          if @course.owner_id_changed?
            Instructor.find(@course.owner_id_was)
          else
            new_owner
          end

        CourseOwnerUpdater.new(@course, previous_owner, new_owner)
      end
    end

    private def update_sections_class_days
      @course.sections.each do |section|
        section.update!(class_days: @course.enterprise_section.class_days)
      end
    end
  end
end
