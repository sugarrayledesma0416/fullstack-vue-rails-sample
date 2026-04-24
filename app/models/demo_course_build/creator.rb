module DemoCourseBuild
  class Creator
    attr_accessor :owner, :program, :students, :params, :errors,
                  :demo_course, :demo_section

    def initialize(params)
      self.errors   = ActiveModel::Errors.new(self)
      self.students = []
      self.params   = params.symbolize_keys
      validate_required_params
    end

    def create_course
      begin
        if valid? && populate_users_and_program
          course_creator = DemoCourseBuild::Course.new(owner: owner, program: program)
          self.demo_course = course_creator.create_demo_course

          if demo_course.valid?
            section_creator = DemoCourseBuild::Section.new(owner: owner, course: demo_course)
            self.demo_section = section_creator.create_demo_section

            if demo_section.valid?
              copier = CourseDataCopier.new(model_course: model_data.model_course,
                                            demo_course: demo_course,
                                            demo_section: demo_section,
                                            students: students)
              copier.populate_demo_course_data
              errors.copy!(copier.errors) unless copier.errors.empty?
            else
              errors.copy!(demo_section.errors)
            end
          else
            errors.copy!(demo_course.errors)
          end
        end

        fail errors.full_messages unless valid?
      rescue StandardError => e
        VHLMonitor.notify(e)
      end

      errors.empty?
    end

    private def populate_users_and_program
      populate_instructor

      self.program = Program.find_by(id: params[:program_id])
      unless program
        add_error("no Program exists matching program_id: #{params[:program_id]}")
      end

      populate_students

      errors.empty?
    end

    private def populate_instructor
      self.owner = Instructor.find_by(id: params[:owner_id])
      if owner && owner.schools.empty?
        add_error("Instructor with id: #{params[:owner_id]} has no school")
      elsif owner.nil?
        add_error("no Instructor exists matching owner_id: #{params[:owner_id]}")
      end
    end

    private def populate_students
      params[:student_ids].each do |student_id|
        if student = Student.find_by(id: student_id)
          students << student
        else
          add_error("no Student exists with specified id: #{student_id}")
        end
      end
    end

    private def add_error(msg)
      errors.add(:base, msg)
    end

    def status
      if valid?
        :ok
      else
        :unprocessable_entity
      end
    end

    def message
      if errors.present?
        { errors: errors.as_json }
      else
        'success'
      end
    end

    private def validate_required_params
      [:owner_id, :program_id, :student_ids].each do |key|
        add_error("#{key} param was missing or blank") if params[key].blank?
      end
    end

    def valid?
      errors.empty?
    end

    private def model_data
      @model_data ||= ModelData.new(program: self.program) if self.program
    end

    private def time_to_sleep
      if Rails.env.live? || Rails.env.staging?
        # TODO: Come up with a nice exponential backoff scheme
        0.5
      else
        0
      end
    end
  end
end
