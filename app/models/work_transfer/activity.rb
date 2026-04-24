module WorkTransfer
  class Activity
    attr_reader :student_guid, :program_id
    attr_accessor :errors

    def initialize(params)
      @student_guid = params[:student_guid]
      @program_id = params[:program_id]
      self.errors = []
    end

    def completed_activities
      student_sections.each_with_object({}) do |section, memo|
        memo[section.guid] = section.attempts
                                    .by_student(student)
                                    .submitted_or_completed
                                    .count
      end
    end

    def messages
      if valid?
        ''
      else
        errors.join(' ')
      end
    end

    def status
      if valid?
        :ok
      else
        :unprocessable_entity
      end
    end

    def student
      @student ||= Student.find_by_guid(student_guid)
    end

    def program
      @program ||= Program.find_by_id(program_id)
    end

    def student_sections
      if student
        student.sections.by_program(program)
      else
        []
      end
    end
    private :student_sections

    def valid?
      validate_program && validate_student && errors.empty?
    end
    private :valid?

    def validate_student
      unless student
        errors << 'Student not found.'
      end
      student
    end
    private :validate_student

    def validate_program
      unless program
        errors << 'Program not found.'
      end
      program
    end
    private :validate_program
  end
end
