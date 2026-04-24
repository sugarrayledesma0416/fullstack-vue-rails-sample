import Rating from './rating'

class OverallComment {
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

  get overallComment() {
    return this.attrs.overallComment;
  }

  get explanation() {
    return this.attrs.explanation;
  }
}

export default OverallComment;
