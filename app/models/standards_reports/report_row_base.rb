module StandardsReports
  class ReportRowBase
    attr_accessor :data_set, :guids, :standard, :student, :activities

    RowData = Struct.new(
      :cms_activity_id,
      :guid,
      :results_data,
      :user_id,
      keyword_init: true
    )

    ResultsData = Struct.new(
      :question_label,
      :points_earned,
      :points_possible,
      keyword_init: true
    )

    def initialize(standard:, student: nil, guid: nil, record: nil, activities: [])
      self.student = student
      self.standard = standard
      self.activities = activities
      self.data_set = []
      add_data(record, guid) if guid && record
    end

    private def average_points_achieved_by_activity(cms_activity_id)
      return if data_set.empty?

      (total_points_earned_by_activity(cms_activity_id).to_f /
       number_of_students_by_activity(cms_activity_id)).round(2)
    end

    private def data_by_activity(cms_activity_id)
      return if data_set.empty?

      data_set.select { |ds| ds.cms_activity_id == cms_activity_id }
    end

    private def number_of_items_by_activity(cms_activity_id)
      data = data_by_activity(cms_activity_id)

      return 0 if data.empty?

      data.map(&:guid).uniq.count
    end

    private def number_of_students_by_activity(cms_activity_id)
      data = data_by_activity(cms_activity_id)

      return 0 if data.empty?

      data.map(&:user_id).uniq.count
    end

    private def points_possible_by_activity(cms_activity_id)
      data = data_by_activity(cms_activity_id)

      return if data.empty?

      standard.guids.sum do |guid|
        data.detect { |set| set.guid == guid }&.results_data&.points_possible || 0
      end
    end

    private def total_points_earned_by_activity(cms_activity_id)
      data = data_by_activity(cms_activity_id)

      return if data.empty?

      data.sum { |set| set.results_data.points_earned }
    end

    def add_data(record, guid)
      data_set << RowData.new(
        cms_activity_id: record.cms_activity_id,
        guid:,
        results_data: ResultsData.new(record.results_data[guid]),
        user_id: record.user_id
      )
    end

    def assessment_summary(cms_activity_id)
      data = data_by_activity(cms_activity_id)

      return [] if data.blank?

      [
        (total_points_earned_by_activity(cms_activity_id).to_f /
         number_of_students_by_activity(cms_activity_id)).round(2),
        points_possible_by_activity(cms_activity_id)
      ]
    end

    def percent_correct_by_activity(cms_activity_id)
      if data_set.empty? ||
         points_possible_by_activity(cms_activity_id).nil? ||
         points_possible_by_activity(cms_activity_id).zero?
        return
      end

      ((average_points_achieved_by_activity(cms_activity_id) /
        points_possible_by_activity(cms_activity_id)) * 100).round(0)
    end

    def total_number_of_items
      return 0 if data_set.empty?

      data_set.map(&:guid).uniq.count
    end
  end
end
