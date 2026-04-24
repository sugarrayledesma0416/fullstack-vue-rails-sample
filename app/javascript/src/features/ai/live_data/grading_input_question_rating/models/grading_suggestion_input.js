import GradingSuggestion from './grading_suggestion';
import OverallComment from './overall_comment';

class GradingSuggestionInput {
  constructor({
    attrs,
    acceptGradingSuggestionRatingCategoryId,
    rejectGradingSuggestionRatingCategoryId,
    acceptOverallCommentRatingCategoryId,
    rejectOverallCommentRatingCategoryId,
  }) {
    this.attrs = attrs;
    this.gradingSuggestions = attrs.gradingSuggestions.map(
      (gradingSuggestionAttrs) => new GradingSuggestion({
        attrs: gradingSuggestionAttrs,
        acceptRatingCategoryId: acceptGradingSuggestionRatingCategoryId,
        rejectRatingCategoryId: rejectGradingSuggestionRatingCategoryId,
      })
    );
    this.overallComments = attrs.overallComments.map(
      (overallCommentAttrs) => new OverallComment({
        attrs: overallCommentAttrs,
        acceptRatingCategoryId: acceptOverallCommentRatingCategoryId,
        rejectRatingCategoryId: rejectOverallCommentRatingCategoryId,
      })
    );
  }

  get studentResponse() {
    return this.attrs.studentResponse;
  }
}

export default GradingSuggestionInput;
