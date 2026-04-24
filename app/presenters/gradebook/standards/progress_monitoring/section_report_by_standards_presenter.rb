module Gradebook
  module Standards
    module ProgressMonitoring
      class SectionReportByStandardsPresenter < SectionReportPresenter
        attr_accessor :categories

        def initialize(section:, program:, **kwargs)
          super(section:, program:, **kwargs)
          self.categories = kwargs[:categories].split(',').map(&:strip)
        end

        def report_formatted_data
          formatted_data = { data: [] }

          standards_data.report_rows.each do |data|
            standard_combined_info = build_standard_combined_info(data)
            activity_data = build_activity_data(data)
            activity_data = sort_activity_data(activity_data)
            formatted_data[:data] << standard_combined_info.merge(activities: activity_data)
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

        private def build_standard_combined_info(data)
          {
            label: data.standard.label,
            id: data.standard.id,
            description: data.standard.description,
            total_number_of_items: data.total_number_of_items
          }
        end

        private def build_activity_info(data, activity, percentage_str)
          {
            results_cell_classes: results_cell_classes(
              data.assessment_summary(activity.cms_activity_id)
            ),
            percentage_color: percentage_color(
              data.percent_correct_by_activity(activity.cms_activity_id)
            ),
            percentage_format: percentage_str,
            result: result(data.assessment_summary(activity.cms_activity_id)),
            category: activity.component_name,
            activity_name: assessment_label(activity),
            submission_count: submission_count(activity.id),
            student_count:
          }
        end

        private def build_activity_data(data)
          activities.map do |activity|
            percentage_str = percentage_format(
              data.percent_correct_by_activity(activity.cms_activity_id)
            )

            next if percentage_str == NO_GRADE_RESULT

            build_activity_info(data, activity, percentage_str)
          end.compact
        end

        private def sort_activity_data(activity_data)
          activity_data.sort_by do |item|
            percent_val = item[:percentage_format].to_i
            # Safely handle non-numeric values by using Float::INFINITY
            (percent_val.is_a? Numeric) ? percent_val : Float::INFINITY
          end
        end
      end
    end
  end
end
