module StandardsReports
  class SingleStudentDetailReportRow
    attr_accessor :data_set, :guid, :activity, :standard

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

    def initialize(guid:, record:, activity:, standard:)
      self.activity = activity
      self.guid = guid
      self.standard = standard
      self.data_set = []
      add_data(record, guid)
    end

    def add_data(record, guid)
      data_set << RowData.new(
        cms_activity_id: record.cms_activity_id,
        guid: guid,
        results_data: ResultsData.new(record.results_data[guid]),
        user_id: record.user_id
      )
    end

    def points_possible
      return if data_set.empty?

      standard.guids.sum do |guid|
        data_set.detect { |set| set.guid == guid }&.results_data&.points_possible || 0
      end
    end

    def points_earned
      return if data_set.empty?

      standard.guids.sum do |guid|
        data_set.detect { |set| set.guid == guid }&.results_data&.points_earned  || 0
      end
    end

    def percent_correct
      return if data_set.empty? || points_possible.zero?

      ((points_earned / points_possible) * 100).round(0)
    end

    def cms_activity_id
      data_set.first.cms_activity_id
    end

    # pass in the percentage range one is interested in,
    # get a true or false returned.
    # e.g. check if percent is between 2 numbers,
    # NOTE that the upper and lower ranges are inclusive so
    # to check if a grade  is >= 80 and < 90, we need to pass in 80,89
    def percent_correct_within_range?(lower, upper)
      percent_correct.between?(lower, upper)
    end
  end
end
