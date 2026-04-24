module Gradebook
  class AnalyticsScorePresenter
    def initialize(section)
      @section = section
    end

    def display_score(student_id, assignment, score, &block)
      if score.nil?
        block.call(unsubmitted_score(student_id, assignment), nil)
      else
        block.call("#{score}%", score_classes(assignment, score))
      end
    end

    def display_score_change(score_change, &block)
      if score_change.nil?
        block.call('--', nil)
      else
        block.call(formatted_difference(score_change), score_change_classes(score_change))
      end
    end

    private def unsubmitted_score(student_id, assignment)
      if assigned_to_student?(student_id, assignment)
        assigned_unsubmitted_score(assignment)
      else
        'N/A'
      end
    end

    private def assigned_to_student?(student_id, assignment)
      return false if assignment.nil?
      return false if @section.current_student_ids.exclude?(student_id.to_i)
      return true unless assignment.individually_assignable

      IndividualAssignment.where(
        user_id: student_id,
        activity_id: assignment.assignable_id,
        section_id: @section.id
      ).exists?
    end

    private def assigned_unsubmitted_score(assignment)
      if after_due_date?(assignment)
        '--'
      else
        ''
      end
    end

    private def score_classes(assignment, score)
      classes = score_value_class(score)

      if !after_due_date?(assignment)
        classes + '  u-txt-ital'
      else
        classes
      end
    end

    private def score_value_class(score)
      case score
      when 'N/A'
        'na-cell'
      when '--'
        'no-score-cell'
      else
        ''
      end
    end

    private def after_due_date?(assignment)
      assignment.due_date < Date.current
    end

    private def score_change_classes(score_change)
      variant = format_class_variant(score_change)
      "c-score-change  c-score-change--#{variant}"
    end

    private def format_class_variant(score_change)
      if score_change.positive?
        'up'
      elsif score_change.negative?
        'down'
      else
        'none'
      end
    end

    private def score_prefix(score_change)
      if score_change.positive?
        '+'
      else
        ''
      end
    end

    private def formatted_difference(score_change)
      "#{score_prefix(score_change)}#{score_change}%"
    end
  end
end
