module Gradebook
  module Standards
    class SectionReportPresenter
      include ProficiencyAssessmentSupport
      include ActionView::Helpers::TagHelper
      attr_accessor :lesson_id, :program, :section, :standard_set_display_name,
                    :standard_id, :sort, :direction,
                    :activity_ids, :unit_id

      delegate :course_id, to: :section
      delegate :id, to: :program, prefix: true
      delegate :name, to: :lesson, prefix: true
      delegate :name, to: :section, prefix: true
      delegate :title, to: :activity, prefix: true
      delegate :name, to: :unit, prefix: true

      VALID_DIRECTIONS = %w[asc desc].freeze

      NO_GRADE_RESULT = '--'.freeze

      def initialize(section:, program:, **kwargs)
        self.section = section
        self.program = program
        self.activity_ids = kwargs[:assessment_ids].split(',').sort if kwargs[:assessment_ids]
        self.lesson_id = kwargs[:lesson_id]
        self.standard_id = kwargs[:standard_id]
        self.standard_set_display_name = kwargs[:standard_set_display_name]
        self.sort = kwargs[:sort]
        self.direction = kwargs[:direction]
        self.unit_id = kwargs[:unit_id]
      end

      def activities
        @activities ||= Activity.find(activity_ids) if activity_ids.present?
      end

      def course
        @course ||= section.course
      end

      def column_headers(first_column_header)
        {}.tap do |memo|
          memo[first_column_header.to_sym] = first_column_header.titleize
          activities.each do |activity|
            label = assessment_label(activity)
            memo[activity.id.to_s.to_sym] = label
            score_count = submission_count(activity.id)
            memo[activity.id.to_s.to_sym] = { label:, student_count:, score_count: }
          end
        end
      end

      def sortable_columns
        @sortable_columns ||=
          {}.tap do |memo|
            memo[:student] = 'Student'
            memo[:standard] = 'Standard'
            activities.each do |activity|
              memo[activity.id.to_s.to_sym] = activity.title
            end
          end
      end

      def lesson
        @lesson ||= Lesson.find_by(id: @lesson_id) if @lesson_id.present?
      end

      def unit
        @unit ||= Unit.find_by(id: @unit_id) if @unit_id.present?
      end

      def unit_name
        unit&.name
      end

      def lessons_for_select
        course.lessons_covered.map do |lesson|
          [lesson.name, lesson.id]
        end
      end

      def percentage_color(percentage)
        case percentage
        when 90..100
          'u-percent-90-to-100'
        when 80..89
          'u-percent-80-to-89'
        when 70..79
          'u-percent-70-to-79'
        when 60..69
          'u-percent-60-to-69'
        when 0..59
          'u-percent-0-to-59'
        end
      end

      def percentage_format(percentage)
        if percentage.is_a? Numeric
          "#{percentage}%"
        else
          percentage || NO_GRADE_RESULT
        end
      end

      def current_column_sort(first_column_header, column_name)
        if sort_column(first_column_header) == sortable_columns[column_name.to_s.to_sym]
          "#{sort_direction}ending"
        else
          'unsorted'
        end
      end

      def sort_column(first_column_header)
        sortable_columns[sort.to_s.to_sym] || first_column_header
      end

      def sort_direction
        VALID_DIRECTIONS.include?(direction) ? direction : 'asc'
      end

      def program_information
        { program_id:, course_id:, section_id: section.id }
      end

      def results_cell_classes(value, section_student_report: false)
        review_modal_classes = if section_student_report && value.present?
                                 '  c-reviewable-item  js-reviewable-item'
                               else
                                 ''
                               end

        base_classes = 'u-pad-rt-18  u-txt-ctr'
        base_classes << review_modal_classes
      end

      def result(value)
        if value.blank?
          nil
        elsif value.is_a?(Array) && value.length >= 2
          points_format(value[0], value[1])
        end
      end

      def points_format(points_earned, points_possible)
        if (points_earned * 10 % 10).zero?
          "(#{points_earned.to_int} of #{points_possible})"
        else
          format('(%.1<points_earned>f of %.1<points_possible>f)', points_earned:, points_possible:)
        end
      end

      def return_params
        {
          assessment_ids: activity_ids.join(','),
          standard_set_display_name:,
          lesson_id:,
          standard_id:
        }
      end

      def standards_data
        if standard_id
          StandardsReports::StudentDetailReportCollection.new(
            activities:,
            section:,
            standard_sets:,
            standard:,
            sort:,
            direction:
          )
        else
          StandardsReports::SectionReportCollection.new(
            activities:,
            section:,
            standard_sets:,
            sort:,
            direction:
          )
        end
      end

      # data for the top standard summary table for the student detail report
      def standards_summary_data
        StandardsReports::SectionReportCollection.new(
          activities:,
          section:,
          standard_sets:,
          standard:
        )
      end

      def standard_sets_for_select
        # Show the display_name when available.
        # When display_name is nil, fall back to "issuer - name".
        course.standard_sets.order(:display_name)
              .pluck(:issuer, :display_name, :name)
              .group_by { |row| [row[1], row[0]] }
              .map { |group, rows| [group[0].presence || "#{group[1]} - #{rows.first[2]}"] }
              .sort_by(&:first)
      end

      def student_count
        section.real_students_base.count
      end

      def submission_count(activity_ids)
        activity = activities.find { |a| a.id.to_s == activity_ids.to_s }
        StandardsResults.count_by_activity_and_section(activity, section)
      end

      def standard_set
        standard_sets.find { |set| set.display_name == standard_set_display_name }
      end

      def report_formatted_data
        formatted_data = { column_headers: [], data: [] }
        if standard_id
          formatted_data[:column_headers] << column_headers('student')
          standards_data.each_row do |data|
            student_combined_info = {
              name: data.student.name,
              id: data.standard.id,
              student_link_data: {
                standard_guid: data.standard.vendor_guid,
                standard_set_id: standard_set&.id,
                student_id: data.student.user_id,
                unit_id: lesson.unit_id,
                unit_name: lesson.label
              }
            }

            formatted_activity_data = activities.map do |activity|
              {
                item_guids: data.data_set.select do |item|
                  item.cms_activity_id == activity.cms_activity_id
                end.pluck(:guid).uniq,
                results_cell_classes: results_cell_classes(data.assessment_summary(activity.cms_activity_id), section_student_report: true),
                percentage_color: percentage_color(data.percent_correct_by_activity(activity.cms_activity_id)),
                percentage_format: percentage_format(data.percent_correct_by_activity(activity.cms_activity_id)),
                result: result(data.assessment_summary(activity.cms_activity_id)),
                standard_label: data.standard.label
              }
            end
            formatted_data[:data] << student_combined_info.merge(activities: formatted_activity_data)
          end
        else
          formatted_data[:column_headers] << column_headers('standard')
          standards_data.report_rows.each do |data|
            standard_combined_info = {
              label: data.standard.label,
              id: data.standard.id,
              description: data.standard.description,
              total_number_of_items: data.total_number_of_items
            }

            formatted_activity_data = activities.map do |activity|
              {
                results_cell_classes: results_cell_classes(data.assessment_summary(activity.cms_activity_id)),
                percentage_color: percentage_color(data.percent_correct_by_activity(activity.cms_activity_id)),
                percentage_format: percentage_format(data.percent_correct_by_activity(activity.cms_activity_id)),
                result: result(data.assessment_summary(activity.cms_activity_id))
              }
            end
            formatted_data[:data] << standard_combined_info.merge(activities: formatted_activity_data)
          end
        end
        formatted_data
      end

      private def standard
        @standard ||= Standard.find(standard_id)
      end

      private def standard_sets
        @standard_sets ||= StandardSet.where(display_name: standard_set_display_name)
                                      .or(StandardSet.where("CONCAT(issuer, ' - ', name) = ?",
                                                            standard_set_display_name))
      end
    end
  end
end
