class CourseSectionUnarchiver

  def initialize
    @unarchived_section_ids = Array.new
    @non_restored_enrollments = Hash.new
    @logger = UnarchiverLogger.new
  end

  def unarchive(section_ids)
    sections(section_ids).each do |section|
      unless section.course
        course(section.course_id).update(is_archived: false)
        section.reload
      end
      if section.is_archived?
        section_instructors(section).update_all(is_archived: false)
        section.update(is_archived: false)
        @logger.log_section(section)
      end
      restore_section_enrollments(section)
    end
  end

  def message
    @logger.messages.join(' ')
  end

  def sections(section_ids)
    Section.unscoped.find(section_ids)
  end
  private :sections

  def course(course_id)
    Course.unscoped.find(course_id)
  end
  private :course

  def section_instructors(section)
    SectionInstructor.unscoped.where(section_id: section.id)
  end
  private :section_instructors

  def restore_section_enrollments(section)
    section.enrollments.each do |enrollment|
      if section.course.closed?
        enrollment.mark_complete
      elsif no_active_enrollment_for_program?(enrollment, section.program)
        enrollment.undrop
      else
        @logger.log_concurrent_enrollment(enrollment)
      end
    end
  end
  private :restore_section_enrollments

  def no_active_enrollment_for_program?(enrollment, program)
    begin
      enrollment.user.current_section_in_program(program).nil?
    rescue ConcurrentSectionsError
      enrollment.drop
      return false
    end
  end
  private :no_active_enrollment_for_program?


  class UnarchiverLogger

    def initialize
      @section_ids = Array.new
      @non_restored_enrollments = Hash.new
    end

    def messages
      [].tap do |messages|
        messages << "The sections with IDs #{@section_ids.join(', ')} have been restored." if @section_ids.present?
        messages << build_enrollments_message if @non_restored_enrollments.present?
        messages << 'None of the sections given were in an archived state.' if messages.empty?
      end
    end

    def log_section(section)
      @section_ids << section.id
    end

    def log_concurrent_enrollment(enrollment)
      @non_restored_enrollments[enrollment.section_id] = Array.new unless @non_restored_enrollments[enrollment.section_id]
      @non_restored_enrollments[enrollment.section_id] << enrollment.user_id
    end

    def build_enrollments_message
      message = "The following enrollments were not restored because of section concurrency: "
      message += @non_restored_enrollments.inject([]) do |memo, (section_id, student_ids)|
          memo << "\"section_id: #{section_id} student_ids: (#{student_ids.join(', ')})\""
          memo
      end.join('. ')
    end
    private :build_enrollments_message

  end


end

