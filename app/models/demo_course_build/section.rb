module DemoCourseBuild
  class Section
    ATTRIBUTES_TO_CLONE = [:name, :additional_info, :class_days, :due_time].freeze
    attr_reader :owner, :course, :errors

    def initialize(owner:, course:)
      @errors = ActiveModel::Errors.new(self)
      @owner = owner
      @course = course
    end

    def create_demo_section
      section = course.sections.build(trial_section_attributes)
      section.section_instructors.build(user_id: owner.id, skip_section_id_validation: true)

      unless section.save
        section.errors.full_messages.each { |message| errors.add(:base, "Section #{message}") }
      end
      section
    end

    private def trial_section_attributes
      model_section_attributes.merge(
        course_id: course.id,
        instructor_id: owner.id,
        time_zone: default_time_zone
      )
    end

    private def model_section_attributes
      model_data.model_section.attributes.reject do |key, value|
        !ATTRIBUTES_TO_CLONE.include?(key.to_sym)
      end
    end

    private def model_data
      @model_data ||= ModelData.new(program: course.program)
    end

    private def school
      course.school
    end

    private def default_time_zone
      if owner.time_zone.present? # need to account for case where owner time zone is empty string
        owner.time_zone
      elsif school.time_zone.present?
        school.time_zone
      else
        Time.zone.name
      end
    end
  end
end
