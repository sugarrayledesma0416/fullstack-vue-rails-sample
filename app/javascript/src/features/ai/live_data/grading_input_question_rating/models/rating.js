class Rating {
  constructor({
    attrs,
    acceptRatingCategoryId,
    rejectRatingCategoryId
  }) {
    if (!attrs) {
      attrs = {
        comment: '',
        ratingCategoryId: null,
      };
    }
    this.acceptRatingCategoryId = acceptRatingCategoryId;
    this.rejectRatingCategoryId = rejectRatingCategoryId;
    this.attrs = attrs;
  }

  get ratingCategoryId() {
    return this.attrs.ratingCategoryId;
  }

  set ratingCategoryId(value) {
    this.attrs.ratingCategoryId = value;
  }

  get accepted() {
    return this.attrs.ratingCategoryId === this.acceptRatingCategoryId;
  }

  get rejected() {
    return this.attrs.ratingCategoryId === this.rejectRatingCategoryId;
  }

  get comment() {
    return this.attrs.comment;
  }

  set comment(value) {
    this.attrs.comment = value;
  }
}

export default Rating;
