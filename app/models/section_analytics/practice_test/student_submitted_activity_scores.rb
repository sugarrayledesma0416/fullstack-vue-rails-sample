module SectionAnalytics
  module PracticeTest
    class StudentSubmittedActivityScores
      # This class gathers an individual student's scores on study plan concepts related to the
      # diagnostic v2 activities provided.  These concepts may not be those of the most recent revision,
      # but rather those that were associated to the activity at the time of activity submission.
      # It receives a concept and searches for the most recent submissions related concepts of the same
      # reference and finds scoresfor it.

      # It's optimized for a student record with eagerly loaded concepts, recommendations,
      # readings, and attempts.  Expect this class to call many queries in the case that those relationships
      # are not eagerly loaded.

      attr_accessor :student, :assignments

      delegate :readings, :attempts, :full_name, :last_name, to: :student
      delegate :id, :full_name, to: :student, prefix: true

      def initialize(student, summative_activity, formative_activities, assignments)
        self.student = student
        @summative_activity = summative_activity
        @formative_activities = formative_activities
        @assignments = assignments
        @section_id = assignments[:summative]&.section_id
      end

      def summative_concept_score_for(concept)
        concept_score(summative_concept_for(concept))
      end

      def formative_concept_score_for(concept)
        concept_score(formative_concept_for(concept))
      end

      def formative_assignment_for(concept)
        assignments[:formative].find do |a|
          a.assignable.study_plan_concepts.map(&:reference_id).include?(concept.reference_id)
        end
      end

      def supplemental_readings_for(concept)
        latest_readings_for(concept).select do |reading|
          reading.recommendation.supplemental?
        end
      end

      def review_readings_for(concept)
        latest_readings_for(concept).select do |reading|
          reading.recommendation.reference? || reading.recommendation.vocabulary?
        end
      end

      private def formative_concept_for(concept)
        formative_concepts.find { |c| c.reference_id == concept.reference_id }
      end

      private def formative_concepts
        @formative_concepts ||= all_formative_concepts.select do |concept|
          recommendation_ids = concept.recommendations.map(&:id)

          readings.select do |reading|
            recommendation_ids.include?(reading.study_plan_concept_recommendation_id)
          end.any?
        end
      end

      private def all_formative_concepts
        @formative_activities.map(&:study_plan_concepts).flatten.uniq
      end

      private def summative_concept_for(concept)
        @summative_activity.study_plan_concepts.find do |study_plan_concept|
          study_plan_concept.reference_id == concept.reference_id
        end
      end

      def concept_score_change(concept)
        summative_score = summative_concept_score_for(concept)
        formative_score = formative_concept_score_for(concept)

        summative_score - formative_score if summative_score.present? && formative_score.present?
      end

      private def concept_score(concept)
        latest_readings_for(concept).first&.concept_score
      end

      private def latest_readings_for(concept)
        readings_for(concept).select do |reading|
          reading.recommendation.study_plan_concept.reference_id == concept.reference_id
        end
      end

      private def readings_for(concept)
        attempt = latest_completed_attempt_for(concept&.activity)
        return [] if attempt.nil?

        readings.select { |r| r.recommendation.study_plan_concept.cms_revision_id == attempt.cms_revision_id }
      end

      private def latest_completed_attempt_for(activity)
        attempts_for(activity&.id).first
      end

      private def attempts_for(activity_id)
        student.attempts.select do |a|
          a.section_id == @section_id && a.activity_id == activity_id && a.completed?
        end
      end
    end
  end
end
