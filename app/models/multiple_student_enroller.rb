class MultipleStudentEnroller
  attr_accessor :section_id, :program_id, :selected_student_ids, :results, :flash_messages

  def initialize(params)
    self.results = { success: [], failed: [], insufficient_access: [], hard_cap_reached: [] }
    self.section_id = params[:selected_section_id].to_i
    self.program_id = params[:program_id].to_i
    self.selected_student_ids = params[:selected_student_ids].map(&:to_i)
    self.flash_messages = {}
  end

  def enroll
    if selected_student_ids.present?
      students_to_enroll = Student.where(id: selected_student_ids)
      self.results = Enrollment.enroll(students_to_enroll, section)
      self.flash_messages = FlashMessageGenerator.generate_messages(message_counts, section.name)
    end
    self
  end

  private def message_counts
    {
      success:  success_count,
      failure:  results[:failed].size,
      hard_cap:  results[:hard_cap_reached].size,
      insufficient_access:  results[:insufficient_access].size
    }
  end

  private def section
    @section ||= Section.find(section_id)
  end

  private def success_count
    # All values in enrollment map are mutually exclusive,
    # but insufficient access students *are* successfully enrolled
    results[:success].size + results[:insufficient_access].size
  end

  class FlashMessageGenerator
    def self.generate_messages(message_counts, section_name)
      # Generates banner parameters for each message type that it receives. Each
      # message type is independent. It is possible to have both success and
      # failure or both success and warning. The most banners we expect to get at
      # once is 3, but all 4 are theoretically possible.
      message_counts.each_with_object({}) do |(msg_type, count), memo|
        next unless count > 0
        banner = const_get(msg_type.to_s.camelcase).new(count, section_name)
        memo[banner.flash_key] = [banner.message]
      end
    end

    class AbstractTemplate
      # Should not be instantiated directly, instead use instances
      # of child classes.
      SUBJECT = 'student'.freeze
      VERB = 'has'.freeze

      attr_accessor :count, :section

      def message
        format(self.class::TEMPLATE, count, subject, verb, section)
      end

      def flash_key
        self.class::FLASH_KEY
      end

      def initialize(count, section)
        self.count = count
        self.section = section
      end

      private def subject
        SUBJECT.pluralize(count)
      end

      private def verb
        VERB.pluralize(count)
      end
    end

    class Success < AbstractTemplate
      # <b>5 students</b> added to My Section.
      TEMPLATE = '<b>%d %s</b> added to %s.'.freeze
      FLASH_KEY = :notice

      def message
        format(self.class::TEMPLATE, count, subject, section)
      end
    end

    class Failure < AbstractTemplate
      # Enrollment failed for <b>5 students</b>.
      TEMPLATE = 'Enrollment failed for <b>%d %s</b>.'.freeze
      FLASH_KEY = :error
    end

    class HardCap < Failure
      # Enrollment failed for <b>5 students</b>. Hard cap has been reached.
      TEMPLATE = (superclass::TEMPLATE +
        ' Site license has no available seats.').freeze
    end

    class InsufficientAccess < AbstractTemplate
      # <b>3 students</b> have insufficient access to complete your course.
      TEMPLATE = '<b>%d %s</b> %s' \
        ' insufficient access to complete your course.'.freeze
      FLASH_KEY = :warning
    end
  end
end
