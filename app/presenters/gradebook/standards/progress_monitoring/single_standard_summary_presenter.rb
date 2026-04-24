module Gradebook
  module Standards
    module ProgressMonitoring
      class SingleStandardSummaryPresenter < SectionReportByAssessmentGroupsPresenter
        def standards_summary_data
          StandardsReports::ProgressMonitoring::ByGroupSectionReportCollection.new(
            activities:,
            section:,
            standard_sets:,
            standard:,
            grouped_activity_ids:
          )
        end

        def report_formatted_data
          {
            column_headers: [column_headers('standard')],
            data: build_standard_data
          }
        end

        private def build_standard_data
          standards_summary_data.report_rows.map do |data|
            standard_combined_info(data).merge(activities: formatted_activity_data(data))
          end
        end

        private def standard_combined_info(data)
          {
            label: data.standard.label,
            id: data.standard.id,
            description: data.standard.description,
            total_number_of_items: data.total_number_of_items
          }
        end

        private def formatted_activity_data(data)
          component_names.map do |component_name|
            {
              results_cell_classes: results_cell_classes(data.assessment_summary(component_name)),
              percentage_color: percentage_color(data.percent_correct_by_group(component_name)),
              percentage_format: percentage_format(data.percent_correct_by_group(component_name)),
              result: result(data.assessment_summary(component_name)),
              category: component_name
            }
          end
        end
      end
    end
  end
end
