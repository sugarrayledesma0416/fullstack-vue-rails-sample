module Gradebook
  module Standards
    class SectionStudentReportController < RequireInstructorController
      include StandardsReportSortable

      layout 'music_v1/responsive'

      before_action :require_standards_course, only: :index

      def index
        @section_report_presenter = section_report_presenter
      end

      def section_report_presenter
        params_hash = filter_params

        if params_hash[:categories].present?
          params_hash = filter_assessments_by_categories(params_hash)
        end

        SectionReportPresenter.new(
          section: current_section,
          program: current_program,
          **params_hash
        )
      end

      def export_csv_standards
        respond_to do |format|
          format.json do
            render json: {
              csv: SectionStudentReport.generate_csv(section_report_presenter)
            }
          end
        end
      end

      def export_student_csv
        respond_to do |format|
          format.json do
            render json: {
              csv: SectionStudentReport.generate_student_csv(section_report_presenter)
            }
          end
        end
      end

      def filter_params
        params.permit(
          :assessment_ids,
          :categories,
          :direction,
          :lesson_id,
          :sort,
          :standard_id,
          :standard_set_display_name,
          :unit_id
        ).to_h.symbolize_keys
      end

      private def report_sort_params(column_name)
        gradebook_standards_section_student_report_path(
          filter_params.merge(column_sort_params(column_name))
        )
      end
      helper_method :report_sort_params

      private def require_standards_course
        current_course = current_section.course
        return if current_course.standard_sets.present?

        flash[:error] = 'This course does not support standards'
        redirect_to gradebook_engine.course_section_analytics_overview_path
      end

      private def filter_assessments_by_categories(params_hash)
        assessment_ids = parse_assessment_ids(params_hash[:assessment_ids])
        selected_categories = params_hash[:categories].split(',').map(&:strip)

        filtered_assessment_ids = Activity
                  .where(id: assessment_ids)
                  .where(component_name: selected_categories)
                  .pluck(:id)

        params_hash.merge(assessment_ids: filtered_assessment_ids.join(','))
      end

      private def parse_assessment_ids(assessment_ids_param)
        assessment_ids_param.to_s.split(',').map(&:strip).map(&:to_i)
      end
    end
  end
end
