class StudentSorter
  attr_reader :sections

  def initialize(sections, opts = {})
    @sections = sections
    @config = opts
  end

  def column
    @config[:column] || 'Name'
  end

  def direction
    @config[:direction] || 'asc'
  end

  def sort_desc?
    direction == 'desc'
  end
  private :sort_desc?

  def category_id
    @config[:category_id] || ''
  end

  def config
    @config
  end
  private :config

  def sort_options?
    config.present?
  end
  private :sort_options?

  def section_students
    @section_students ||= lambda do
      if sections.present?
        GradebookStudent.decorate(
          Student.enrolled_in_sections(sections.to_a).to_a,
          sections.first.program,
          sections
        )
      else
        []
      end
    end.call
  end

  def students
    # The memoize method is causing some weird problems here.
    @students ||= section_students.sort do |student_a, student_b|
      compare(student_a.sortable_name, student_b.sortable_name)
    end
  end

  private def compare(a, b)
    b, a = a, b if sort_desc?
    a <=> b
  end
end
