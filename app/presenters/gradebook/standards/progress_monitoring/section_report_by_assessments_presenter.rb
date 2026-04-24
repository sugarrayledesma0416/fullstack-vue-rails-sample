module Gradebook
  module Standards
    module ProgressMonitoring
      class SectionReportByAssessmentsPresenter < SectionReportPresenter
        attr_accessor :categories

        def initialize(section:, program:, **kwargs)
          super(section:, program:, **kwargs)
          self.categories = kwargs[:categories].split(',').map(&:strip)
        end

        def column_headers(first_column_header, second_column_header)
          {}.tap do |memo|
            memo[first_column_header.to_sym] = first_column_header.titleize
            memo[second_column_header.to_sym] = second_column_header.titleize
          end
        end

        def report_formatted_data
          formatted_data = initialize_formatted_data
          report_rows_standards_data = standards_data.report_rows
          activities = report_rows_standards_data.first&.activities || []

          activities.each do |activity|
            formatted_data[:data] << format_activity_data(activity, report_rows_standards_data)
          end

          formatted_data
        end

        def activities
          @activities ||= if activity_ids.present?
                            Activity
                              .where(id: activity_ids, component_name: categories)
                              .group_by(&:component_name)
                              .values
                              .flatten
                          end
        end

        private def initialize_formatted_data
          { column_headers: [column_headers('progress_monitoring', 'standards')], data: [] }
        end

        private def format_activity_data(activity, report_rows_standards_data)
          formatted_activity_data = report_rows_standards_data.map do |data|
            format_individual_activity_data(data, activity.cms_activity_id)
          end
          formatted_activity_data = formatted_activity_data.compact.sort_by do |item|
            percent_val = item[:percentage_format].to_i
            # ideally we should not get any non-numeric values but
            # percentage_format method in base class has code to handle for non numeric values
            (percent_val.is_a? Numeric) ? percent_val : Float::INFINITY
          end

          build_activity_combined_info(activity).merge(activities: formatted_activity_data)
        end

        private def build_activity_combined_info(activity)
          {
            label: activity.title,
            id: activity.id,
            category: activity.component_name,
            submission_count: submission_count(activity.id),
            student_count:
          }
        end

        private def format_individual_activity_data(data, cms_activity_id)
          percentage_str = percentage_format(
            data.percent_correct_by_activity(cms_activity_id)
          )
          if percentage_str == NO_GRADE_RESULT
            nil
          else
            individual_activity_data(data, cms_activity_id, percentage_str)
          end
        end

        private def individual_activity_data(data, cms_activity_id, percentage_str)
          {
            results_cell_classes: results_cell_classes(data.assessment_summary(cms_activity_id)),
            percentage_color: percentage_color(data.percent_correct_by_activity(cms_activity_id)),
            percentage_format: percentage_str,
            result: result(data.assessment_summary(cms_activity_id)),
            standard_id: data.standard.id,
            standard_name: data.standard.label,
            standard_description: data.standard.description
          }
        end
      end
    end
  end
end
