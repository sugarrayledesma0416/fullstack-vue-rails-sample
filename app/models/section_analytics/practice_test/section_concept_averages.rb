module SectionAnalytics
  module PracticeTest
    class SectionConceptAverages
      attr_accessor :concept

      delegate :reference_id, :activity, to: :concept

      def initialize(concept, students)
        self.concept = concept
        @students = students
      end

      def average
        @average ||= scores.any? ? (scores.reduce(0, :+) / scores.count) : 0
      end

      def summative_average
        @summative_average ||= if summative_scores.any?
                                 summative_scores.reduce(0, :+) / summative_scores.count
                               else
                                 0
                               end
      end

      def score_change
        summative_average - average
      end

      private def scores
        @scores ||= @students.map { |s| s.formative_concept_score_for(concept) }.compact
      end

      private def summative_scores
        return @summative_scores if instance_variable_defined? :@summative_scores

        @summative_scores = @students.map do |student|
          student.summative_concept_score_for(concept)
        end.compact
      end
    end
  end
end
