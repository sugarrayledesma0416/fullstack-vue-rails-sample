module Gradebook
  module Standards
    class SectionReportController < RequireInstructorController
      include StandardsReportSortable

      layout 'music_v1/responsive'

      before_action :require_standards_program, only: :index

      def index
        redirect_to(gradebook_standards_landing_page_path(
                    course_id: current_section.course.id,
                    program_id: current_program.id,
                    section_id: current_section.id))
      end

      def assessments
        selected_lesson = Lesson.find_by(id: params[:selected_lesson_id])
        lesson_activities = fetch_lesson_activities(selected_lesson)

        assessments = lesson_activities&.select(&:proficiency_assessment?)&.map do |assessment|
          [assessment.title, assessment.id]
        end

        render json: { assessments:, status: :ok }
      end

      def categories
        selected_lesson = Lesson.find_by(id: params[:selected_lesson_id])
        lesson_activities = fetch_lesson_activities(selected_lesson)

        progress_monitoring_assessments = lesson_activities
                                          .includes(:lesson, :concept)
                                          &.select(&:progress_monitoring_assessment?)

        categories = progress_monitoring_assessments&.map(&:component_name)&.uniq
        assessment_ids = progress_monitoring_assessments&.map(&:id)

        render json: { categories:, assessment_ids:, status: :ok }
      end

      def valid_filters?
        return false if filter_params.blank?

        filter_params.values.none?(&:blank?)
      end
      helper_method :valid_filters?

      private def filter_params
        params.permit(
          :assessment_ids,
          :direction,
          :lesson_id,
          :sort,
          :standard_set_display_name
        ).to_h.symbolize_keys
      end

      private def require_standards_program
        return if current_program.supports_standards?

        current_course = current_section.course

        flash[:error] = 'This program does not support standards'
        redirect_to gradebook_engine.course_section_analytics_overview_path
      end

      private def fetch_lesson_activities(selected_lesson)
        activities = selected_lesson&.activities(
          sections: [current_section],
          current_user:
        )
        activities.where.not(cms_activity_id: nil).order(:toc_location_rank) if activities
      end
    end
  end
end
