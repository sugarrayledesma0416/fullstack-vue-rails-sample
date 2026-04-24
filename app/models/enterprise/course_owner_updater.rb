module Enterprise
  class CourseOwnerUpdater < ::CourseOwnerUpdater
    public :valid?

    def initialize(course, previous_owner, new_owner)
      super(course, new_owner)
      @previous_owner = previous_owner
      @previous_owner.extend(CourseOwnerUtilities)
    end

    def update
      return unless to_update? && valid?

      Course.transaction do
        @course.sections.each do |section|
          transfer_section(section)
        end
      end
    end

    def to_update?
      @previous_owner != @new_owner
    end

    # skip instructor type validations for owners
    # only apply course validations
    private def validations
      %i[validate_course]
    end
  end
end
