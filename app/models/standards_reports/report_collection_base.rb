module StandardsReports
  class ReportCollectionBase
    attr_accessor :activities, :rows, :section

    StandardInfo = Struct.new(
      :description, :guids, :id, :label, :vendor_guid, keyword_init: true
    ) do
      def ==(other)
        vendor_guid == other.vendor_guid
      end

      def <=>(other)
        label <=> other.label
      end
    end

    StudentInfo = Struct.new(:user_id, :name, keyword_init: true) do
      def ==(other)
        user_id == other.user_id
      end

      def <=>(other)
        name <=> other.name
      end
    end

    def initialize
      self.rows = []
    end

    def each_row(&block)
      report_rows.each(&block)
    end

    def report_rows
      return @report_rows if defined?(@report_rows)

      # This will populate self.rows
      init_report_rows

      # apply student results
      standards_results.each do |record|
        add_row(record)
      end

      # create sort methods for activity columns
      activities.each { |activity| create_activity_sort_method(activity) }

      @report_rows = sort_rows
    end

    private def create_activity_sort_method(activity)
      self.class.send(:define_method, "sort_by_#{activity.id}") do |dir|
        sort_direction(
          # when percent_correct is nil, use -1 to separate them from 0%
          rows.sort_by do |a|
            [a.percent_correct_by_activity(activity.cms_activity_id) || -1,
             a.send(secondary_sort_method)]
          end,
          dir
        )
      end
    end

    # Sort method names start with "sort_by_" and end with the column name param value
    # and accept a direction value, 'asc' or 'desc'.
    # If direction is nil, default is 'asc'.
    private def sort_rows
      if sort.blank?
        default_sort
      else
        send("sort_by_#{sort}", direction)
      end
    end

    private def sort_by_standard(dir)
      sort_direction(rows.sort_by(&:standard), dir)
    end

    private def sort_by_number_of_items(dir)
      sort_direction(
        rows.sort_by { |a| [a.total_number_of_items.to_i, a.send(secondary_sort_method)] },
        dir
      )
    end

    private def sort_direction(sorted, dir)
      if dir == 'desc'
        sorted.reverse
      else
        sorted
      end
    end

    private def default_sort
      raise NoMethodError, "Inheriting class must implement `#{__method__}`"
    end

    private def secondary_sort_method
      raise NoMethodError, "Inheriting class must implement `#{__method__}`"
    end

    private def init_report_rows
      raise NoMethodError, "Inheriting class must implement `#{__method__}`"
    end

    private def add_row
      raise NoMethodError, "Inheriting class must implement `#{__method__}`"
    end

    def find_or_create_row
      raise NoMethodError, "Inheriting class must implement `#{__method__}`"
    end

    private def standards_results
      @standards_results ||= StandardsResults.where(
        section_id: section,
        cms_activity_id: activities.pluck(:cms_activity_id).uniq,
        user_id: students.map(&:user_id)
      )
    end

    private def alignments
      @alignments ||= StandardAlignment
                      .select(:vendor_standard_guid, 'assessment_items.guid AS item_guid')
                      .joins(standard_asset: :assessment_item)
                      .where(
                        assessment_items: { assessment_id: activities.pluck(:cms_activity_id) }
                      )
    end

    private def alignment_question_guids(standard_guid)
      alignments.select do |align|
        align.vendor_standard_guid == standard_guid
      end.map(&:item_guid)
    end

    private def standard_label(standard)
      # If standard has no number, use truncated description, which is required but not unique.
      standard.number.presence || standard.description.truncate(30)
    end

    private def students
      return @students if defined?(@students)

      # sample student is not included
      @students = section.real_students_base.map do |student|
        StudentInfo.new(
          user_id: student.id,
          name: student.last_name_first
        )
      end
    end
  end
end
