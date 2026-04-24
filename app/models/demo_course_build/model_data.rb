module DemoCourseBuild
  class ModelData
    attr_reader :program, :errors

    def initialize(program:)
      @errors = ActiveModel::Errors.new(self)
      @program = program
    end

    def model_instructor
      @model_instructor ||= Instructor.find_by_username('model_demo_instructor')
    end

    def model_course
      @model_course ||= model_instructor && model_instructor.courses.by_program(program).first
    end

    def model_section
      @model_section ||= model_course && model_course.sections.first
    end

    def model_students
      @model_students ||= model_section.students
    end

    def model_data_exists?
      if model_instructor.blank?
        errors.add(:base, "no model demo instructor was found")
      elsif model_course.blank?
        errors.add(:base, "no model demo course was found for program: #{self.program.id}")
      elsif model_section.blank?
        errors.add(:base, "no model demo section was found for program: #{self.program.id}")
      elsif model_students.empty?
        errors.add(:base, "no students exist in the model course for program: #{self.program.id}")
      end

      errors.empty?
    end
  end
end
