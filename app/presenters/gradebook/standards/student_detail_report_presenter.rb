module Gradebook
  module Standards
    class StudentDetailReportPresenter
      attr_accessor :section, :standard_set, :student, :available_sets

      MID_LITERAL = 'Mid'.freeze
      END_LITERAL = 'End-of'.freeze
      UNIT_LITERAL = 'Unit'.freeze
      BOOK_LITERAL = 'Book'.freeze
      SERIES_KEY_REGEX = /((#{MID_LITERAL}|#{END_LITERAL})-(#{UNIT_LITERAL}|#{BOOK_LITERAL}))/i

      def initialize(section_id:, standard_set_id:, student_id:)
        raise('user_id keyword argument is required.') if student_id.nil?
        raise('section_id keyword argument is required.') if section_id.nil?
        raise('standard_set_id keyword argument is required.') if standard_set_id.nil?

        @section = Section.find(section_id)
        @standard_set = StandardSet.find(standard_set_id)
        @student = User.find(student_id)
        @available_sets = @section.course
                                  .standard_sets.select(:id, :display_name)
                                  .group_by(&:display_name).to_json
      end

      def chart_data
        {
          assessments_by_series:,
          assessments_by_unit:,
          cumulative_average:,
          end_book_unit_name:,
          mid_book_unit_name:,
          units:
        }
      end

      def cumulative_average
        # Get array of hashes for each unit, e.g. [{ 'mid-unit': 100, 'end-unit': 100 }, ...]
        assessment_hashes_for_units = assessments_by_unit.values

        # Extract the values from each hash, e.g. [[100, 100], ...]
        array_of_score_arrays = assessment_hashes_for_units.map(&:values)

        # Flatten to a one-dimensional array; remove nil values
        scores = array_of_score_arrays.flatten.compact

        # Guard against division by zero
        return nil if scores.empty?

        scores.sum / scores.size
      end

      private def units
        @units ||= @section.course.program.units.sort_by(&:rank).map do |unit|
          unit.slice(:id, :name, :rank, :label)
              .symbolize_keys
        end
      end

      private def assessments
        @section.assignments.map(&:assignable).select do |activity|
          activity.assessment? && activity.proficiency_assessment?
        end
      end

      private def assessments_by_unit
        @assessments_by_unit ||= assessments
                                 .each_with_object(unit_series_hash) do |assessment, memo|
          # If the title matches the regex, convert the matching string to lowercase to get the key.
          # Otherwise, skip the assessment - we need scores for the matching assessments only.
          #
          # NOTE: This line assumes that the title for a proficiency assessment will always match
          #       the regex. If the title doesn't match, the attempted index access throws an error.
          title_key = SERIES_KEY_REGEX.match(assessment.title)[1]
          next(memo) unless title_key

          # Skip the assessment if the student's score should not be included in the chart or
          # the cumulative average.
          next(memo) unless gradebook_score(assessment.id)

          unit_id = assessment.lesson.unit_id
          memo[unit_id][title_key] = gradebook_score(assessment.id)
        end
      end

      private def assessments_by_series
        series_keys.index_with do |series_key|
          units.map { |unit| assessments_by_unit[unit[:id]][series_key] }
        end
      end

      # Return a hash that maps each series key to `nil`.
      # This is to ensure that there's a value for every series key in each unit.
      private def series_hash
        Hash[*series_keys.map { |key| [key, nil] }.flatten]
      end

      # Return a hash that maps each key to a series hash.
      # Unit IDs are the intended keys.
      private def unit_series_hash
        Hash.new { |h, k| h[k] = series_hash }
      end

      private def include_score?(current_score_action)
        # Return false if
        # - the student has not submitted the assessment
        # - the instructor has reset the student's attempt
        #   - in both of these cases, the score action will have no `submitted_at` value
        # - the score is pending
        current_score_action.submitted_at.present? && !current_score_action.pending?
      end

      private def gradebook_score(assessment_id)
        # Map each activity ID to a simple point_earned/points_possible calculation.
        #
        # If the score should not be included in the chart or the cumulative average,
        # set its value as `nil`.
        @user_scores ||= GradebookEngine::CurrentScoreAction.where(
          section_id: @section.id, user_id: @student.id
        ).to_h do |sa|
          points_earned, points_possible = sa.slice(:points_earned, :points_possible).values
          score_for_display = (points_earned.to_f * 100 / points_possible)
          [sa.activity_id, include_score?(sa) ? score_for_display : nil]
        end

        @user_scores[assessment_id]
      end

      private def series_keys
        [UNIT_LITERAL, BOOK_LITERAL].map do |level|
          [MID_LITERAL, END_LITERAL].map do |location|
            "#{location}-#{level}"
          end
        end.flatten
      end

      private def unit_name_for_book_assessment_type(book_assessment_type)
        assessment = assessments.select do |a|
          /#{book_assessment_type}-Book/i.match a.title
        end.first

        return '' if assessment.nil?

        assessment.lesson
                  .unit
                  .name
                  .split(' | ')
                  .send(:[], 0) || ''
      end

      private def mid_book_unit_name
        unit_name_for_book_assessment_type(MID_LITERAL)
      end

      private def end_book_unit_name
        unit_name_for_book_assessment_type(END_LITERAL)
      end
    end
  end
end
