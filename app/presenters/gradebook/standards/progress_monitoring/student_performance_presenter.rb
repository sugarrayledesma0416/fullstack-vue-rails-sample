module Gradebook
  module Standards
    module ProgressMonitoring
      class StudentPerformancePresenter < SectionReportByAssessmentGroupsPresenter
        def standards_data
          standard_id ? build_progress_monitoring_report : super
        end

        def report_formatted_data
          return { column_headers: [], data: [] } unless standard_id

          {
            column_headers: [column_headers('student')],
            data: build_student_data
          }
        end

        private def build_student_data
          standards_data.each_row.map do |data|
            student_combined_info(data).merge(activities: formatted_activity_data(data))
          end
        end

        private def student_combined_info(data)
          {
            name: data.student.name,
            id: data.standard.id,
            student_link_data: {
              lesson_id: lesson.id,
              standard_guid: data.standard.vendor_guid,
              standard_set_id: standard_set&.id,
              student_id: data.student.user_id,
              unit_id: lesson.unit_id,
              unit_name: lesson.label
            }
          }
        end

        private def formatted_activity_data(data)
          component_names.map do |component_name|
            {
              item_guids: filtered_item_guids(data, grouped_activity_ids[component_name]),
              results_cell_classes: calculate_results_cell_classes(data, component_name),
              percentage_color: percentage_color(data.percent_correct_by_group(component_name)),
              percentage_format: percentage_format(data.percent_correct_by_group(component_name)),
              result: result(data.assessment_summary(component_name)),
              standard_label: data.standard.label
            }
          end
        end

        private def filtered_item_guids(data, activity_ids)
          data.data_set.select { |item| activity_ids.include?(item.cms_activity_id) }
              .pluck(:guid).uniq
        end

        private def build_progress_monitoring_report
          StandardsReports::ProgressMonitoring::ByGroupStudentDetailReportCollection.new(
            activities:,
            section:,
            standard_sets:,
            standard:,
            sort:,
            direction:,
            grouped_activity_ids:
          )
        end

        private def calculate_results_cell_classes(data, component_name)
          results_cell_classes(
            data.assessment_summary(component_name),
            section_student_report: true
          )
        end
      end
    end
  end
end
