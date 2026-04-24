module Gradebook
  module Standards
    class StudentDetailReportController < RequireInstructorController
      helper MaestroActivityEngine::ActivitiesHelper
      include RequireStandardsProgramCourse
      layout 'music_v1/responsive'

      before_action :require_standards_program_and_course, only: :index

      def show
        assessment_item = AssessmentItem.find_by(guid: params[:assessment_item_guid])
        @activity = Activity.joins(lesson: [unit: :program])
                            .where(cms_activity_id: assessment_item.assessment_id)
                            .where(activities: {
                                     lessons: { units: { program_id: params[:program_id] } }
                                   }).first

        # We want all references but the first since it is the direction line
        @references = question_section(@activity, assessment_item).references[1..-1]
        @question = question_content(@activity, assessment_item)
        # We want the latest attempt in case the student has more than one for the specific activity
        @attempt = Attempt.where(activity_id: @activity.id, user_id: params[:student_id]).last
        @title = @activity.title
        render layout: nil, status: :ok
      end

      def grade_categories
        standard_ids = filter_params[:standard_set_id].to_s.split(',').map(&:to_i)

        break_down = StudentUnitBreakdownReportPresenter.new(
          unit: Unit.find(filter_params[:unit_id]),
          section: current_section,
          student: User.find(filter_params[:student_id]),
          standard_sets: StandardSet.find(standard_ids)
        ).range_breakdown_standards_counts

        render json: { assessments: break_down, status: :ok }
      end

      def filter_params
        params
          .permit(
            :lower,
            :section_id,
            :standard_set_id,
            :student_id,
            :unit_id,
            :upper,
            :sort,
            :sort_column,
            :program_id,
            :course_id,
            :student_detail_report
          )
          .to_h
          .symbolize_keys
      end

      def standard_list_by_range
        standard_ids = filter_params[:standard_set_id].to_s.split(',').map(&:to_i)

        presenter = StudentUnitBreakdownReportPresenter.new(
          unit: Unit.find(filter_params[:unit_id]),
          section: current_section,
          student: User.find(filter_params[:student_id]),
          standard_sets: StandardSet.find(standard_ids)
        )

        break_down = presenter.range_breakdown_results(filter_params[:lower].to_i, filter_params[:upper].to_i)

        guids = break_down.keys
        summary = {}.tap do |memo|
          guids.each { |guid| memo[guid.to_sym] = presenter.standard_unit_assessments_summary(guid.to_s)}
        end

        sort_direction = filter_params[:sort].to_i == 1 ? :asc : :desc
        sorted_break_down = sort_break_down_by_key(break_down, :"#{filter_params[:sort_column]}", sort_direction)

        render json: { assessments: sorted_break_down, summary:, status: :ok }
      end

      private def data_for_student_detail_report
        return nil if section_report_params_missing?

        {
          standard_guid: params[:standard_guid],
          unit: {
            id: params[:unit_id],
            name: params[:unit_name]
          }
        }
      end

      private def section_report_params_missing?
        params[:standard_guid].blank? || params[:unit_id].blank? || params[:unit_name].blank?
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

      private def sort_break_down_by_key(hash, key, order)
        sorted_hash = hash.sort_by { |_, data| data[key] }

        if order == :desc
          sorted_hash.reverse.to_h
        else
          sorted_hash.to_h
        end
      end

      private def require_standards_program_and_course
        current_course = current_section.course
        return if current_course.standard_sets.present? && current_program.supports_standards?

        if current_course.standard_sets.blank?
          flash[:error] = 'This course does not support standards'
        end

        unless current_program.supports_standards?
          flash[:error] = 'This program does not support standards'
        end

        redirect_to gradebook_engine.course_section_analytics_overview_path
      end
    end
  end
end
