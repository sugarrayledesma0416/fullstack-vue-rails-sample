module AI
  class GradingPromptsPresenter
    GRADING_SUGGESTION_SELECT = <<~SQL.squish.freeze
      ai_grading_suggestion_prompts.id as prompt_id,
      ai_suggestion_rating_categories.id as category_id,
      ai_suggestion_rating_categories.label,
      count(ai_grading_suggestion_ratings.id) as rating_count
    SQL

    OVERALL_COMMENT_SELECT = <<~SQL.squish.freeze
      ai_overall_comment_prompts.id as prompt_id,
      ai_suggestion_rating_categories.id as category_id,
      ai_suggestion_rating_categories.label,
      count(ai_overall_comment_ratings.id) as rating_count
    SQL

    def initialize
      # Trigger sync from AI Core and experiments
      GradingSuggestionPrompt.current
      OverallCommentPrompt.current
      GradingSuggestionPrompt.sync_experiment_prompts_if_needed
      OverallCommentPrompt.sync_experiment_prompts_if_needed
    end

    def grading_suggestion_prompts
      # Order: active first, then by source priority, then newest first
      @grading_suggestion_prompts = GradingSuggestionPrompt.all.sort_by do |prompt|
        [
          prompt.active_for_instructor_grading? ? 0 : 1, # Active first
          source_priority(prompt.source), # Then by source priority
          -prompt.id # Then newest first
        ]
      end
    end

    def overall_comment_prompts
      # Order: active first, then by source priority, then newest first
      @overall_comment_prompts = OverallCommentPrompt.all.sort_by do |prompt|
        [
          prompt.active_for_instructor_grading? ? 0 : 1, # Active first
          source_priority(prompt.source), # Then by source priority
          -prompt.id # Then newest first
        ]
      end
    end

    def using_ai_core_for_grading_suggestions?
      GradingSuggestionPrompt.using_ai_core_source?
    end

    def using_ai_core_for_overall_comments?
      OverallCommentPrompt.using_ai_core_source?
    end

    def current_grading_suggestion_prompt
      @current_grading_suggestion_prompt ||= GradingSuggestionPrompt.current
    end

    def current_overall_comment_prompt
      @current_overall_comment_prompt ||= OverallCommentPrompt.current
    end

    def grading_suggestion_stats(prompt_id)
      suggestion_ratings[prompt_id]
    end

    def overall_comment_stats(prompt_id)
      overall_ratings[prompt_id]
    end

    private def overall_ratings
      populate_statistics(overall_ratings_scope)
    end

    private def suggestion_ratings
      populate_statistics(suggestion_ratings_scope)
    end

    private def overall_ratings_scope
      OverallCommentPrompt.select(OVERALL_COMMENT_SELECT).left_outer_joins(
        overall_comments: { ratings: :rating_category }
      ).group(
        'ai_overall_comment_prompts.id, ai_suggestion_rating_categories.id'
      ).order(
        'ai_overall_comment_prompts.id, ai_suggestion_rating_categories.label'
      )
    end

    private def suggestion_ratings_scope
      GradingSuggestionPrompt.select(GRADING_SUGGESTION_SELECT).left_outer_joins(
        grading_suggestions: { ratings: :rating_category }
      ).group(
        'ai_grading_suggestion_prompts.id, ai_suggestion_rating_categories.id'
      ).order(
        'ai_grading_suggestion_prompts.id, ai_suggestion_rating_categories.label'
      )
    end

    private def populate_statistics(scope)
      scope.group_by(&:prompt_id).transform_values do |value|
        Statistics.new(value)
      end
    end

    private def source_priority(source)
      case source
      when 'experiment'
        1
      when 'ai_core'
        2
      when 'm3', 'manual'
        3
      else
        4
      end
    end

    class Statistics
      attr_accessor :results

      def initialize(results)
        self.results = results
      end

      def empty?
        total_count.zero?
      end

      def total_count
        @total_count ||= results.sum(&:rating_count)
      end

      def categories
        return [] if empty?

        results.select(&:label).map do |result|
          percentage = (result.rating_count.to_f / total_count * 100).round(1)
          { label: result.label, percentage: }
        end
      end
    end
  end
end
