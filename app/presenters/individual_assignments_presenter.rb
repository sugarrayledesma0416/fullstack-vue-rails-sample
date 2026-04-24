class IndividualAssignmentsPresenter
  include GradebookEngine::StringNormalization

  M_D_YY_FORMAT = '%-m/%-d/%y'.freeze
  M_D_YYYY_FORMAT = '%-m/%-d/%Y'.freeze

  attr_accessor :params, :section_id

  def initialize(section_id, params)
    self.section_id = section_id
    self.params = params
  end

  def entries
    @entries ||= format_entries(
      apply_lesson_scope(
        apply_week_scope(
          entries_scope.order(:last_name, :first_name)
        )
      ).to_a
    ).group_by(&:user_id_with_prefix)
  end

  def to_csv
    CSV.generate(encoding: 'windows-1252') do |csv|
      CsvData.new(entries).rows.each { |row| csv << row }
    end
  end

  def lesson_options
    program = Program.find(params[:program_id])
    [default_lesson_option] + program.lessons.map do |lesson|
      {
        name: normalize(lesson.display_name),
        selected: params[:lesson_id].to_i == lesson.id,
        value: lesson.id
      }
    end
  end

  def week_options
    [default_week_option] + course.weeks_covered.map do |week|
      {
        name: week_name(week),
        selected: params[:week] == week.to_s,
        value: week.to_s
      }
    end
  end

  def min_due_date
    course.start_date.strftime(M_D_YYYY_FORMAT)
  end

  def max_due_date
    course.end_date.strftime(M_D_YYYY_FORMAT)
  end

  private def format_entries(records)
    records.each { |record| record.extend FormattedEntry }
  end

  private def apply_lesson_scope(scope)
    if params[:lesson_id].blank?
      scope
    else
      scope.where(activities: { lesson_id: params[:lesson_id] })
    end
  end

  private def apply_week_scope(scope)
    if params[:week].blank?
      scope
    else
      week_start = Date.parse(params[:week])
      week_end = week_start + 7.days
      scope.where(
        'assignments.due_date >= ? AND assignments.due_date < ?',
        week_start, week_end
      )
    end
  end

  private def default_lesson_option
    { name: 'All Lessons', selected: params[:lesson_id].blank?, value: '' }
  end

  private def default_week_option
    { name: 'All Weeks', selected: params[:week].blank?, value: '' }
  end

  # Get the week names into the format needed for the dropdown
  # Format: "Week #: m/d/yy - m/d/yy"
  private def week_name(date)
    week_number = course.week_number(date)
    "Week #{week_number}: #{m_d_yy(date)} - #{m_d_yy(date.end_of_week(:sunday))}"
  end

  private def m_d_yy(date)
    date.strftime(M_D_YY_FORMAT)
  end

  private def section
    @section ||= Section.find(section_id)
  end

  private def course
    @course ||= section.course
  end

  private def base_scope
    SectionIndividualAssignmentsQuery.assignments(@section_id)
  end

  private def entries_scope
    if params[:activity_ids].present?
      base_scope.where(assignable_id: params[:activity_ids])
    elsif only_individual_csv?
      base_scope.where(assignments: { individually_assignable: true })
    else
      base_scope
    end
  end

  private def only_individual_csv?
    params[:format] == 'csv' && params[:only_individual] == 'true'
  end

  module FormattedEntry
    include GradebookEngine::StringNormalization

    def due_date
      self[:due_date].strftime(M_D_YYYY_FORMAT)
    end

    def individual_due_date
      self[:individual_due_date]&.strftime(M_D_YYYY_FORMAT)
    end

    def activity_title
      normalize(self[:activity_title])
    end

    # rubocop:disable Style/DoubleNegation
    def individually_assigned
      !!self[:individually_assigned]
    end
    # rubocop:enable Style/DoubleNegation

    def strand_name
      normalize(self[:strand_name])
    end

    # Add a method that prepends "user_" to the user_id,
    # for use as a key in the entries hash.
    # Using a string key rather than an integer key preserves
    # the order of the entries when the client-side JavaScript
    # runs JSON.parse on the entries JSON.
    def user_id_with_prefix
      "user_#{self[:user_id]}"
    end
  end

  class CsvData
    attr_accessor :entries

    def initialize(entries)
      self.entries = entries
    end

    def rows
      header_rows + body_rows
    end

    private def header_rows
      header = entries.values.first
      return [] unless header

      [
        header_row(header, &:strand_name),
        header_row(header, &:activity_title),
        ['', 'Individually Assignable'] + csv_assignment_status(header),
        ['Last name', 'First name'] + header.map(&:due_date)
      ]
    end

    private def body_rows
      entries.values.map do |activity_entries|
        csv_student_name_cells(activity_entries) +
          csv_student_activity_cells(activity_entries)
      end
    end

    private def csv_assignment_status(header)
      header.map do |entry|
        entry.individually_assignable? ? 'yes' : 'no'
      end
    end

    private def header_row(header_data, &block)
      ['', ''] + header_data.map(&block)
    end

    private def csv_student_name_cells(activity_entries)
      student_entry = activity_entries.first
      [student_entry.last_name, student_entry.first_name]
    end

    private def csv_student_activity_cells(activity_entries)
      activity_entries.map do |entry|
        if !entry.individually_assignable? || entry.individually_assigned?
          'x'
        else
          ''
        end
      end
    end
  end
end
