module Gradebook
  module Standards
    class LandingPageController < RequireInstructorController
      helper MaestroActivityEngine::ActivitiesHelper
      include RequireStandardsProgramCourse
      include StandardsReportSortable
      layout 'music_v1/responsive'

      before_action :require_standards_program_and_course, :set_presenters, only: %i[index report]

      def index; end

      def show
        assessment_item = AssessmentItem.find_by(guid: params[:assessment_item_guid])
        @activity = Activity.joins(lesson: [unit: :program])
                            .where(cms_activity_id: assessment_item.assessment_id)
                            .where(activities: {
                                     lessons: { units: { program_id: params[:program_id] } }
                                   }).first

        # We want all references but the first since it is the direction line
        @references = question_section(@activity, assessment_item).references[1..]
        @question = question_content(@activity, assessment_item)
        # We want the latest attempt in case the student has more than one for the specific activity
        @attempt = Attempt.where(activity_id: @activity.id, user_id: params[:student_id]).last
        @title = @activity.title
        render layout: nil, status: :ok
      end

      def valid_filters?
        return false if @filter_params.except(:student_id).blank?

        @filter_params.except(:student_id).values.none?(&:blank?)
      end
      helper_method :valid_filters?

      def report
        unless valid_filters?
          render plain: 'Invalid parameter(s)', status: :bad_request
          return
        end

        assessment_data = {
          section_name: current_section.name,
          lesson_name: @section_report_presenter.lesson_name,
          unit_id: @section_report_presenter.lesson.unit_id,
          valid_filters: valid_filters?,
          student_count: @section_report_presenter.student_count.zero?,
          report_rows: @section_report_presenter.report_formatted_data,
          assistant_role_policy: assistant_role_policy.is_assistant?,
          # optional and additional data for progress monitoring detail page only
          individual_performance_data: pmr_individual_performance
        }

        render json: { assessments: assessment_data }, status: :ok
      end

      private def pmr_individual_performance
        return unless @filter_params[:assessment_type] == 'progress_monitoring' &&
                      @filter_params[:standard_id].present?

        @pmr_presenter = ProgressMonitoring::StudentPerformancePresenter.new(
          section: current_section,
          program: current_program,
          **@filter_params
        )

        pmr_individual_performance_response
      end

      private def pmr_individual_performance_response
        {
          section_name: current_section.name,
          lesson_name: @pmr_presenter.lesson_name,
          unit_id: @pmr_presenter.lesson.unit_id,
          valid_filters: valid_filters?,
          student_count: @pmr_presenter.student_count.zero?,
          report_rows: @pmr_presenter.report_formatted_data,
          assistant_role_policy: assistant_role_policy.is_assistant?
        }
      end

      private def data_for_student_detail_report
        unit = if params[:unit_id].present?
                 {
                   id: params[:unit_id],
                   name: params[:unit_name]
                 }
               end
        {
          standard_guid: params[:standard_guid] || nil,
          unit:
        }
      end

      private def filter_params
        params.permit(
          :assessment_ids,
          :categories,
          :assessment_type,
          :direction,
          :lesson_id,
          :sort,
          :standard_id,
          :standard_set_display_name,
          :student_id,
          :view_by
        ).to_h.symbolize_keys
      end

      private def question_content(activity, assessment_item)
        activity.content_object.questions.find do |q|
          q.question_guid == assessment_item.guid
        end
      end

      private def question_section(activity, assessment_item)
        activity.content_object.activities.find do |section|
          section.questions.any? do |question|
            question.question_guid == assessment_item.guid
          end
        end
      end

      private def report_sort_params(column_name)
        gradebook_standards_landing_page_path(
          filter_params.merge(column_sort_params(column_name))
        )
      end
      helper_method :report_sort_params

      private def presenter_class
        if progress_monitoring_for_single_standard?
          ProgressMonitoring::SingleStandardSummaryPresenter
        elsif progress_monitoring_by_standards_view?
          ProgressMonitoring::SectionReportByStandardsPresenter
        elsif progress_monitoring?
          ProgressMonitoring::SectionReportByAssessmentsPresenter
        else
          SectionReportPresenter
        end
      end

      private def progress_monitoring?
        @filter_params[:assessment_type] == 'progress_monitoring'
      end

      private def progress_monitoring_for_single_standard?
        progress_monitoring? && @filter_params[:standard_id].present?
      end

      private def progress_monitoring_by_standards_view?
        progress_monitoring? && @filter_params[:view_by] == 'standards'
      end

      private def set_presenters
        @filter_params = filter_params
        @standard_set_id = params[:standard_set_id] || current_section.course.standard_sets.first.id
        @data_for_student_detail_report = data_for_student_detail_report
        @section_report_presenter = presenter_class.new(
          section: current_section,
          program: current_program,
          **@filter_params
        )

        return if current_section.current_students_base.blank?

        default_student = current_section.current_students_base.first.id
        @student_id = (@filter_params[:student_id].presence || default_student).to_i
        @students = current_section.current_students_base.sort_by(&:last_name).to_json

        @student_detail_report_presenter = StudentDetailReportPresenter.new(
          section_id: current_section.id,
          standard_set_id: @standard_set_id,
          student_id: @student_id
        )
      end
    end
  end
end
