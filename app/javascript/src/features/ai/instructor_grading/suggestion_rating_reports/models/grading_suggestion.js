class GradingSuggestion {
  constructor(suggestionData) {
    this.id = suggestionData.id;
    this.incorrectText = suggestionData.incorrectText;
    this.errorExplanation = suggestionData.errorExplanation;
    this.prompt = suggestionData.prompt;
    this.ratingCategory = suggestionData.ratingCategory;
    this.ratingComment = suggestionData.ratingComment;
  }
}

export default GradingSuggestion;
