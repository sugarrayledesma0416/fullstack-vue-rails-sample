import GradingSuggestion from './grading_suggestion';
import OverallComment from './overall_comment';

class StudentResponse {
  constructor(responseData) {
    this.attemptId = responseData.attemptId;
    this.studentResponse = responseData.studentResponse;
    this.gradingSuggestions = responseData.gradingSuggestions.map(
      (gradingSuggestionAttrs) => new GradingSuggestion({
        ...gradingSuggestionAttrs,
        ratingCategory: responseData.ratingCategories.find(
          (category) => category.id === gradingSuggestionAttrs.ratingCategoryId
        ),
        prompt: responseData.gradingSuggestionPrompts.find(
          (prompt) => prompt.id === gradingSuggestionAttrs.promptId
        ),
      })
    );
    this.overallComments = responseData.overallComments.map(
      (overallCommentAttrs) => new OverallComment({
        ...overallCommentAttrs,
        ratingCategory: responseData.ratingCategories.find(
          (category) => category.id === overallCommentAttrs.ratingCategoryId
        ),
        prompt: responseData.overallCommentPrompts.find(
          (prompt) => prompt.id === overallCommentAttrs.promptId
        ),
      })
    );
  }
}

export default StudentResponse;
