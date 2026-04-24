class AssignmentSetList
  # Provides remove_br_tags method
  include GradebookEngine::StringNormalization
  include Rails.application.routes.url_helpers

  attr_accessor :section

  ASSIGNMENT_SELECT = <<~SQL.freeze
    activities.id as activity_id,
    activities.activity_type,
    activities.instructor_id,
    activities.title as activity_title,
    activities.toc_location_rank,
    assignment_sets.id as assignment_set_id,
    asa.assignment_set_rank,
    concepts.id as strand_id,
    concepts.name as strand_name,
    concepts.background_color as strand_color,
    concepts.rank as concept_rank,
    lessons.id as lesson_id,
    lessons.label as lesson_label,
    lessons.name as lesson_name,
    assignments.due_date,
    assignments.section_id,
    assignments.rank as toc_rank
  SQL

  ASSIGNMENT_JOIN = <<~SQL.freeze
    INNER JOIN concepts ON concepts.id = activities.concept_id
    INNER JOIN lessons ON lessons.id = activities.lesson_id
    LEFT OUTER JOIN assignment_sets ON
      assignment_sets.section_id = assignments.section_id AND
      assignment_sets.due_date = assignments.due_date
    LEFT OUTER JOIN assignment_set_activities asa ON
      asa.assignment_set_id = assignment_sets.id AND
      asa.activity_id = assignments.assignable_id
  SQL

  ASSIGNMENT_ORDER = Arel.sql(
    'assignments.due_date ASC, COALESCE(asa.assignment_set_rank, assignments.rank) ASC'
  )

  ASSIGNMENT_DEFAULT_ORDER = Arel.sql(
    'assignments.due_date ASC, assignments.rank ASC'
  )

  def initialize(section)
    self.section = section
  end

  def entries
    {
      custom_order: assignments_current_order,
      default_order: assignments_default_order
    }
  end

  # When we are explicitly passing the default activity order,
  # although an assignment set may exist for this date,
  # do not include the assignment set id. The default order is
  # used as a template for reverting to default order in the client.
  private def group_assignment_data(assignments, default = false)
    assignments.group_by(&:due_date).map do |due_date, rows|
      first_row = rows.first
      {
        due_date: due_date,
        due_date_string: due_date.strftime('%A %b %-d'),
        id: default ? nil : first_row.assignment_set_id,
        section_id: first_row.section_id,
        activities: activity_data(sort_no_custom_ordered(rows, default), default)
      }
    end
  end

  def to_csv(filters = {})
    default_filters = {
      start_date: section.course_start_date,
      end_date: section.course_end_date
    }

    filters = if filters[:start_date].present? && filters[:end_date].present?
                default_filters.merge(filters)
              else
                default_filters
              end

    CSV.generate(encoding: 'windows-1252') do |csv|
      CsvData.new(
        unordered_assignment_scope.order(ASSIGNMENT_ORDER)
      ).rows(filters).each { |row| csv << row }
    end
  end

  private def activity_data(rows, default = false)
    rows.map { |row| activity_attrs(row, default) }
  end

  private def activity_attrs(row, default = false)
    row.attributes.symbolize_keys.slice(
      :activity_id, :strand_id, :strand_color, :toc_rank
    ).merge(
      assignment_set_rank: default ? nil : row.assignment_set_rank,
      activity_title: remove_br_tags(row.activity_title),
      activity_type: row.activity_type,
      lesson_name: remove_br_tags(row.lesson_label.presence || row.lesson_name),
      strand_name: remove_br_tags(row.strand_name),
      url: section_activity_path(id: row.activity_id, section_id: 0),
      toc_location_rank: row.toc_location_rank
    )
  end

  # when there is no custom order we need to show the same workset order
  # adding assessments(activity_type = exam) to the bottom of each lesson
  # and IGC at the top of each strand. We also want to keep the strands(concept) order
  # as it is in the TOC.
  private def sort_no_custom_ordered(rows, default = false)
    # if we are ordering the default set, do the exam sort.
    unless default
      # if not default, but assignment set exists, don't do the exam sort.
      return rows if rows.first.assignment_set_id
    end

    rows.sort_by(&:lesson_id)

    rows.group_by(&:lesson_id).transform_values! do |lesson_rows|
      lesson_rows.sort_by do |row|
        [
          row.concept_rank,
          row.activity_type != 'exam' && row.instructor_id ? 0 : 1,
          # A default value is needed here as there are published
          # activities with a nil toc_location_rank. Doing a sort_by
          # with an array containing nil values results in
          # ArgumentError: comparison of Array with Array failed.
          # The default value prevents that error.
          row.toc_location_rank || 0,
          row.activity_id
        ]
      end
    end.values.flatten
  end

  def unordered_assignment_scope
    @unordered_assignment_scope ||= Assignment.by_type(Activity)
                                              .by_section(section)
                                              .select(ASSIGNMENT_SELECT)
                                              .joins(ASSIGNMENT_JOIN)
  end

  # The current assignment order. This may be the order from an
  # assignment set or it may be the default order if no assignment set
  # exists for the due date.
  private def assignments_current_order
    group_assignment_data(unordered_assignment_scope.order(ASSIGNMENT_ORDER))
  end

  # The assignment order ignoring any assignment set rankings.
  # Used to reset an assignment set to 'default order' in the
  # client side assignment ordering feature.
  private def assignments_default_order
    group_assignment_data(unordered_assignment_scope.order(ASSIGNMENT_DEFAULT_ORDER), true)
  end

  class CsvData
    # Provides normalize method
    include GradebookEngine::StringNormalization

    HEADER_ROW = [
      'Due Date',
      'Has Custom Order',
      'Rank',
      'Lesson',
      'Strand',
      'Activity'
    ].freeze

    attr_accessor :base_scope

    def initialize(base_scope)
      self.base_scope = base_scope
    end

    def rows(filters)
      [HEADER_ROW] + body_rows(filters)
    end

    private def body_rows(filters)
      filtered_scope(**filters).map { |entry| entry_attrs(entry) }
    end

    private def entry_attrs(entry)
      [
        entry.due_date.strftime('%-m/%d'),
        entry.assignment_set_id ? 'Yes' : 'No',
        entry.assignment_set_rank.presence || entry.toc_rank,
        normalize(entry.lesson_label.presence || entry.lesson_name),
        normalize(entry.strand_name),
        normalize(entry.activity_title)
      ]
    end

    private def filtered_scope(start_date:, end_date:)
      base_scope.where(
        'assignments.due_date BETWEEN ? AND ?',
        start_date,
        end_date
      )
    end
  end
end
