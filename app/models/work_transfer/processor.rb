module WorkTransfer
  class Processor

    attr_reader :student_guid, :origin_section_guid, :dest_section_guid, :processor_errors

    delegate :course, to: :origin_section, prefix: true, allow_nil: true
    delegate :course, to: :dest_section, prefix: true, allow_nil: true
    delegate :valid?, to: :processor_errors

    def initialize(args)
      @student_guid = args[:student_guid]
      @origin_section_guid = args[:origin_section_guid]
      @dest_section_guid = args[:destination_section_guid]
      @processor_errors = Processor::ProcessorError.new
    end

    def process
      validate
      if valid?
        PreviousSectionTransferWorker.perform_async(student.id, origin_section.id, dest_section.id)
      end
      self
    end

    def validate
      # We first call all validations to set all possible error messages on the errors array.
      validate_origin_section
      validate_destination_section
      validate_student
      validate_program if origin_section_guid && dest_section_guid
    end
    private :validate

    def messages
      if valid?
        'Student work is being transfered, please check in a few minutes.'
      else
        processor_errors.full_messages
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
    private :student

    def get_section(section_id)
      Section.find_by_guid(section_id)
    end
    private :get_section

    def validate_origin_section
      processor_errors.add('Origin section not found.') unless origin_section
    end
    private :validate_origin_section

    def dest_section
      @dest_section ||= get_section(dest_section_guid)
    end
    private :dest_section

    def origin_section
      @origin_section ||= get_section(origin_section_guid)
    end
    private :origin_section

    def validate_destination_section
      processor_errors.add('Destination section not found.') unless dest_section
    end
    private :validate_destination_section

    def validate_student
      processor_errors.add('Student not found.') unless student
    end
    private :validate_student

    def origin_section_program_id
      origin_section_course && origin_section_course.program_id
    end
    private :origin_section_program_id

    def dest_section_program_id
      dest_section_course && dest_section_course.program_id
    end
    private :dest_section_program_id

    def validate_program
      processor_errors.add('Sections you want to transfer student work are not from the same program.')unless origin_section_program_id == dest_section_program_id
    end
    private :validate_program

    class ProcessorError
      def initialize
        @errors = []
      end

      def add(message)
        @errors << message
      end

      def valid?
        @errors.empty?
      end

      def full_messages
        @errors.join(' ')
      end
    end

  end
end
