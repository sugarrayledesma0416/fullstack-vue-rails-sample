import Rating from './rating'

class GradingSuggestion {
  constructor({
    attrs,
    acceptRatingCategoryId,
    rejectRatingCategoryId
  }) {
    this.attrs = attrs;
    this.rating = new Rating({
      attrs: this.attrs.rating,
      acceptRatingCategoryId: acceptRatingCategoryId,
      rejectRatingCategoryId: rejectRatingCategoryId,
    });
  }

  get id() {
    return this.attrs.id;
  }

  get incorrectText() {
    return this.attrs.incorrectText;
  }

  get errorExplanation() {
    return this.attrs.errorExplanation;
  }
}

export default GradingSuggestion;
