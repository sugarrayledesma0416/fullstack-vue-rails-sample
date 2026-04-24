module Jr
  class TocPresenter
    include TocPresenterCommon
    include StudentTocPresentation

    attr_accessor :course, :current_user, :lesson, :program, :section, :strand

    def initialize(lesson:, program:, section: nil, strand:, user:)
      self.course = section&.course
      self.current_user = user
      self.lesson = lesson
      self.program = program
      self.section = section
      self.strand = strand
    end

    def activities
      # assigning lesson to the returned activities reduces the objects
      # created and reduces parsing of lesson xml
      @activities ||= ::Activity.where(id: activities_to_show_ids).order(
        'instructor_revision_id DESC, toc_location_rank ASC'
      ).each { |activity| activity.lesson = lesson }
    end

    def section_id
      section&.id || 0
    end

    def current_topic
      strand.location
    end
    alias grading_strand current_topic
  end
end
