module StandardsReports
  module ProgressMonitoring
    class ByGroupReportRowBase
      attr_accessor :activities, :data_set, :grouped_activity_ids, :guids, :standard, :student

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

      def initialize(
        standard:,
        student: nil,
        guid: nil,
        record: nil,
        activities: [],
        grouped_activity_ids: {}
      )
        self.student = student
        self.standard = standard
        self.activities = activities
        self.grouped_activity_ids = grouped_activity_ids
        self.data_set = []
        add_data(record, guid) if guid && record
      end

      private def average_points_achieved_by_group(component_name)
        return if data_set.empty?

        (total_points_earned_by_group(component_name).to_f /
        number_of_students_by_group(component_name)).round(2)
      end

      private def data_by_group(component_name)
        return if data_set.empty?

        activity_ids = grouped_activity_ids[component_name]
        data_set.select { |ds| activity_ids&.include?(ds.cms_activity_id) }
      end

      private def number_of_items_by_group(component_name)
        data = data_by_group(component_name)

        return 0 if data.empty?

        data.map(&:guid).uniq.count
      end

      private def number_of_students_by_group(component_name)
        data = data_by_group(component_name)

        return 0 if data.empty?

        data.map(&:user_id).uniq.count
      end

      private def points_possible_by_group(component_name)
        data = data_by_group(component_name)

        return if data.empty?

        standard.guids.sum do |guid|
          data.detect { |set| set.guid == guid }&.results_data&.points_possible || 0
        end
      end

      private def total_points_earned_by_group(component_name)
        data = data_by_group(component_name)

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

      def assessment_summary(component_name)
        data = data_by_group(component_name)

        return [] if data.blank?

        [
          (total_points_earned_by_group(component_name).to_f /
          number_of_students_by_group(component_name)).round(2),
          points_possible_by_group(component_name)
        ]
      end

      def percent_correct_by_group(component_name)
        if data_set.empty? ||
           points_possible_by_group(component_name).nil? ||
           points_possible_by_group(component_name).zero?
          return
        end

        ((average_points_achieved_by_group(component_name) /
          points_possible_by_group(component_name)) * 100).round(0)
      end

      def total_number_of_items
        return 0 if data_set.empty?

        data_set.map(&:guid).uniq.count
      end
    end
  end
end
