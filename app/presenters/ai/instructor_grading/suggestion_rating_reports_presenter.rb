module AI
  module InstructorGrading
    class SuggestionRatingReportsPresenter < ActionView::Base
      include ApplicationHelper
      include ActivitiesHelper
      include ::TocPresenterCommon
      # "Standard" means "not Supersite Junior"
      include ::StandardTocPresentation
      include LessonAndStrandsPresenter
      include Music::ApplicationHelper

      ACTIVITY_TYPES = %w[
        open_ended
        composition
      ].freeze

      attr_reader(
        :activity_type,
        :grading_suggestion_prompt,
        :overall_comment_prompt,
        :program
      )

      attr_accessor :current_user, :current_program

      def initialize(
        activity_type:,
        grading_suggestion_prompt:,
        overall_comment_prompt:,
        program:,
        req_params:, lesson_ids: [],
        selected_strands: [],
        selected_instructors: []
      )
        @activity_type = (activity_type || '').split(',')
        @grading_suggestion_prompt = grading_suggestion_prompt
        @overall_comment_prompt = overall_comment_prompt
        @program = program
        @lesson_ids = (lesson_ids || '').split(',')
        @selected_strands = (selected_strands || '').split(',')
        @selected_instructors = (selected_instructors || '').split(',')
        @req_params = req_params
      end

      def format_activity_icons(activity)
        format_activity_label_with_icons(
          dom_id(activity),
          activity,
          nil,
          nil,
          false,
          true,
          false
        )
      end

      # Returns a list of instructors with grading suggestions.
      def instructors_with_grading_suggestion
        @instructors_with_grading_suggestion ||= Instructor.where(id: activity_ids_with_rated_instructor.values.compact.uniq)
      end

      def rejected_comments_by_activity(activity_id)
        comments_counts_by_activity(activity_id)[AI::GradingSuggestion::REJECTED_STATUS]
      end

      def accepted_comments_by_activity(activity_id)
        comments_counts_by_activity(activity_id)[AI::GradingSuggestion::ACCEPTED_STATUS]
      end

      private def comments_counts_by_activity(activity_id)
        @comments_counts_by_activity ||= grading_sugestions_base_query
          .where(activity_id:,
                reviewed_status: [AI::GradingSuggestion::REJECTED_STATUS, AI::GradingSuggestion::ACCEPTED_STATUS])
          .group(:reviewed_status)
          .count
      end

      def hash_activity_keys
        Activity.activity_types_mapping.slice(*ACTIVITY_TYPES.map(&:to_sym))
      end

      # Returns information about all the activities matching the filters.
      def entries
        @entries ||= WillPaginate::Collection.create(current_page, per_page,
                                                    current_strand_activities.size) do |pager|
          pager.replace(current_strand_activities.slice(offset, per_page) || [])
        end
      end

      private def per_page
        10
      end

      private def current_page
        (req_params[:page] || 1).to_i
      end

      private def offset
        (current_page - 1) * per_page
      end

      private def all_activities
        activity_ids_from_rated_grading_suggestions = grading_sugestions_base_query
                                                      .where.not(rated_by_id: nil)
                                                      .distinct(:activity_id)
                                                      .pluck(:activity_id)
        activity_ids_from_rated_overall_comments = overall_comments_base_query
                                                   .where.not(rated_by_id: nil)
                                                   .distinct(:activity_id)
                                                   .pluck(:activity_id)

        Activity.where(
          id: activity_ids_from_rated_grading_suggestions + activity_ids_from_rated_overall_comments
        )
      end

      def routes
        Rails.application.routes.url_helpers
      end

      # Return all the activities in the current strand with AI suggestions rated
      # by an instructor.
      private def current_strand_activities
        activity_data = activity_ids_with_rated_instructor
        activity_ids = activity_data.keys

        instructors = instructors_with_grading_suggestion.index_by(&:id)

        grading_counts = grading_sugestions_base_query
                         .where(activity_id: activity_ids)
                         .group(:activity_id)
                         .count

        Activity.where(id: activity_ids).map do |activity|
          {
            activity:,
            rated_by_instructor: instructors[activity_data[activity.id]],
            grading_suggestions_count: grading_counts[activity.id] || 0,
            details_path: routes.ai_program_instructor_grading_suggestion_rating_reports_question_path(
              program_id: program.id,
              activity_id: activity.id,
              instructor_id: instructors[activity_data[activity.id]]
            )
          }
        end
      end

      # Returns a hash of activity IDs with their rated instructor IDs.
      private def activity_ids_with_rated_instructor
        @activity_data ||= begin
          grading_suggestions_query = grading_sugestions_base_query
                                    .joins(:activity)
                                    .where.not(rated_by_id: nil)
                                    .where(activities: {activity_type: activity_types})
          overall_comments_query = overall_comments_base_query
                                  .joins(:activity)
                                  .where.not(rated_by_id: nil)
                                  .where(activities: {activity_type: activity_types})

          if @selected_instructors.reject(&:blank?).present?
            grading_suggestions_query = grading_suggestions_query.where(rated_by_id: @selected_instructors)
            overall_comments_query = overall_comments_query.where(rated_by_id: @selected_instructors)
          end

          if @lesson_ids.reject(&:blank?).present?
            grading_suggestions_query = grading_suggestions_query.where(activities: { lesson_id: lesson_ids })
            overall_comments_query = overall_comments_query.where(activities: { lesson_id: lesson_ids })
          end

          if @selected_strands.reject(&:blank?).present?
            grading_suggestions_query = grading_suggestions_query.where(activities: { toc_location: @selected_strands })
            overall_comments_query = overall_comments_query.where(activities: { toc_location: @selected_strands })
          end

          grading_suggestions_sql = grading_suggestions_query
                        .select('DISTINCT ai_grading_suggestions.activity_id, ai_grading_suggestions.rated_by_id')
                        .to_sql

          overall_comments_sql = overall_comments_query
                        .select('DISTINCT ai_overall_comments.activity_id, ai_overall_comments.rated_by_id')
                        .to_sql

          result = AI::OverallComment.find_by_sql("#{grading_suggestions_sql} UNION #{overall_comments_sql}").pluck(:activity_id, :rated_by_id)
          result.to_h
        end
      end

      private def grading_sugestions_base_query
        @grading_sugestions_base_query ||= AI::GradingSuggestion.non_internal.with_prompt(grading_suggestion_prompt&.id)
      end

      private def overall_comments_base_query
        @overall_comments_base_query ||= AI::OverallComment.non_internal.with_prompt(overall_comment_prompt&.id)
      end

      private def lesson_ids
        @lesson_ids.any? ? @lesson_ids : program.lessons.pluck(:id)
      end

      private def activity_types
        @activity_types ||= activity_type.any? ? activity_type : ACTIVITY_TYPES
      end

      private def filter_out_activities_with_no_flagged_suggestions?
        !false
      end

      module LessonWithAIInstructorRatedSuggestions
        attr_accessor :toc_locations_with_rated_suggestions

        def strands
          @strands ||= toc_entries.select do |toc_entry|
            toc_locations_with_rated_suggestions.include?(toc_entry.location.to_i)
          end
        end
      end
    end
  end
end
