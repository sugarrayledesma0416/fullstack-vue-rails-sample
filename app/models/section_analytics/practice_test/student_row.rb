module SectionAnalytics
  module PracticeTest
    class StudentRow
      attr_accessor :student_scores

      delegate :student, :student_full_name, :student_id, to: :student_scores

      def initialize(student:, summative_activity:, formative_activities:, assignments:)
        @summative_activity = summative_activity

        @student_scores = SectionAnalytics::PracticeTest::StudentSubmittedActivityScores.new(
          student,
          summative_activity,
          formative_activities,
          assignments
        )
      end

      def concept_score_groups
        distinct_summative_concepts.map do |concept|
          {
            formative: {
              score: @student_scores.formative_concept_score_for(concept),
              assignment: @student_scores.formative_assignment_for(concept),
            },
            summative: {
              score: @student_scores.summative_concept_score_for(concept),
              assignment: @student_scores.assignments[:summative]
            },
            change: @student_scores.concept_score_change(concept),
            supplemental_readings: @student_scores.supplemental_readings_for(concept),
            review_readings: @student_scores.review_readings_for(concept),
            # This is only used in specs to ensure the correct order of the concepts.
            _reference_id: concept.reference_id
          }
        end
      end

      # Each time a diagnostic activity is published, m3 creates new study plan concepts.
      # This creates the potential to have groups of study plan concepts for each revision.  This method
      # ensures that we retireve the most recent group, counting concepts based off of the current content object.
      private def distinct_summative_concepts
        @distinct_summative_concepts ||= summative_concepts
                                         .order(reference_id: :asc)
                                         .limit(summative_concepts_count)
      end

      private def summative_concepts_count
        @summative_activity.content_object.concepts.count
      end

      private def summative_concepts
        @summative_activity.study_plan_concepts.where(
          cms_revision_id: @summative_activity.cms_revision_id
        )
      end
    end
  end
end
