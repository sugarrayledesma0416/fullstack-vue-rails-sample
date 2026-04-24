class Setting < ApplicationRecord
  #define new settings here, namespacing within modules whenever appropriate

  module Gradebook
    class CategoryView < Definition
      LESSONS = 'lessons'
      WEEKS   = 'weeks'

      validates_inclusion_in_constants

      default LESSONS
    end

    class Timeframe < Definition
      CURRENT = 'current'
      ALL     = 'all'

      validates_inclusion_in_constants

      default CURRENT
    end

    class GradeDisplayStyle < Definition
      PERCENT = 'percent'
      POINTS  = 'points'
      MARK    = 'mark'

      validates_inclusion_in_constants

      default PERCENT
    end
  end

  module GradingTasks
    class ShowAutoGradedQuestions < Definition
      default '1'
    end

    class GradingStyle < Definition
      BY_STUDENT = 'student_by_student'
      BY_QUESTION = 'question_by_question'
      SPOTCHECK = 'spotcheck'

      validates_inclusion_in_constants

      default BY_STUDENT
    end

    class SpotcheckStyle < Definition
      RANDOM = 'random'
      OUTLIERS = 'outliers'
      MANUAL = 'manual'

      validates_inclusion_in_constants

      default RANDOM
    end

    class SpotcheckSelectedRandomStudentsCount < Definition
      default 'All'
    end

    class SpotcheckSelectedOutliersCount < Definition
      default 'All'
    end
  end

  module AI
    class AllowGradingSuggestions < Definition
      TRUE_VAL = 'true'
      FALSE_VAL = 'false'

      validates_inclusion_in_constants

      default FALSE_VAL
    end

    class EnableGradingSuggestions < Definition
      TRUE_VAL = 'true'
      FALSE_VAL = 'false'

      validates_inclusion_in_constants

      default FALSE_VAL
    end
  end

  def self.default(name)
    Definition.get_default(name)
  end

  belongs_to :user
end
