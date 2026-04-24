import { defineStore } from 'pinia';
import GradingSuggestionInput from './grading_suggestion_input';
import * as ajaxUtils from 'shared/ajax_utils';

const useQuestionRatingStore = defineStore({
  id: 'questionRatingStore',
  actions: {
    init({
      gradingSuggestionInputsAttrs,
      acceptGradingSuggestionRatingCategoryId,
      rejectGradingSuggestionRatingCategoryId,
      rateGradingSuggestionUrl,
      acceptOverallCommentRatingCategoryId,
      rejectOverallCommentRatingCategoryId,
      rateOverallCommentUrl
    }) {
      this.gradingSuggestionInputs = gradingSuggestionInputsAttrs.map(
        (attrs) => new GradingSuggestionInput({
          attrs: attrs,
          acceptGradingSuggestionRatingCategoryId: acceptGradingSuggestionRatingCategoryId,
          rejectGradingSuggestionRatingCategoryId: rejectGradingSuggestionRatingCategoryId,
          acceptOverallCommentRatingCategoryId: acceptOverallCommentRatingCategoryId,
          rejectOverallCommentRatingCategoryId: rejectOverallCommentRatingCategoryId,
        })
      );
      this.acceptGradingSuggestionRatingCategoryId = acceptGradingSuggestionRatingCategoryId;
      this.rejectGradingSuggestionRatingCategoryId = rejectGradingSuggestionRatingCategoryId;
      this.rateGradingSuggestionUrl = rateGradingSuggestionUrl;
      this.acceptOverallCommentRatingCategoryId = acceptOverallCommentRatingCategoryId;
      this.rejectOverallCommentRatingCategoryId = rejectOverallCommentRatingCategoryId;
      this.rateOverallCommentUrl = rateOverallCommentUrl;
    },

    acceptSuggestion(gradingSuggestion, rating) {
      this.rateGradingSuggestion(
        gradingSuggestion,
        rating,
        this.acceptGradingSuggestionRatingCategoryId,
        ''
      );
      rating.ratingCategoryId = this.acceptGradingSuggestionRatingCategoryId;
      rating.comment = '';
    },

    rejectSuggestion(gradingSuggestion, rating, comment) {
      this.rateGradingSuggestion(
        gradingSuggestion,
        rating,
        this.rejectGradingSuggestionRatingCategoryId,
        comment
      );
      rating.ratingCategoryId = this.rejectGradingSuggestionRatingCategoryId;
      rating.comment = comment;
    },

    rateGradingSuggestion(gradingSuggestion, rating, ratingCagtegoryId, comment) {
      const url = `${this.rateGradingSuggestionUrl}/${gradingSuggestion.id}/rate`;

      // Save current state in order to revert the changes if the ajax call fails.
      let previousRatingCategoryId = rating.ratingCategoryId;
      let previousComment = rating.comment;

      // Update the rating
      rating.ratingCategoryId = ratingCagtegoryId;
      rating.comment = comment;

      ajaxUtils.putToEndpoint(
        url,
        {
          rating_category_id: ratingCagtegoryId,
          comment: comment,
        },
        (data) => {
          if (!data.ok) {
            console.log('Failed to rate grading suggestion:', data);
            rating.ratingCategoryId = previousRatingCategoryId;
            rating.comment = previousComment;
          } else if (data.errors) {
            console.log('Failed to rate grading suggestion:', data.errors);
            rating.ratingCategoryId = previousRatingCategoryId;
            rating.comment = previousComment;
          }
        }
      );
    },

    acceptOverallComment(overallComment, rating) {
      this.rateOverallComment(
        overallComment,
        rating,
        this.acceptOverallCommentRatingCategoryId,
        ''
      );
    },

    rejectOverallComment(overallComment, rating, comment) {
      this.rateOverallComment(
        overallComment,
        rating,
        this.rejectOverallCommentRatingCategoryId,
        comment
      );
    },

    rateOverallComment(overallComment, rating, ratingCagtegoryId, comment) {
      const url = `${this.rateOverallCommentUrl}/${overallComment.id}/rate`;

      // Save current state in order to revert the changes if the ajax call fails.
      let previousRatingCategoryId = rating.ratingCategoryId;
      let previousComment = rating.comment;

      // Update the rating
      rating.ratingCategoryId = ratingCagtegoryId;
      rating.comment = comment;

      ajaxUtils.putToEndpoint(
        url,
        {
          rating_category_id: ratingCagtegoryId,
          comment: comment,
        },
        (data) => {
          if (!data.ok) {
            console.log('Failed to rate overall comment:', data);
            rating.ratingCategoryId = previousRatingCategoryId;
            rating.comment = previousComment;
          } else if (data.errors) {
            console.log('Failed to rate overall comment:', data.errors);
            rating.ratingCategoryId = previousRatingCategoryId;
            rating.comment = previousComment;
          }
        }
      );
    },
  }
});

export default useQuestionRatingStore;
