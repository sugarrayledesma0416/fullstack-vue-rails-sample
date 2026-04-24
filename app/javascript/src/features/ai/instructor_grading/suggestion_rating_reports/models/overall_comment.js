class OverallComment {
  constructor(overallCommentData) {
    this.id = overallCommentData.id;
    this.overallComment = overallCommentData.overallComment;
    this.explanation = overallCommentData.explanation;
    this.prompt = overallCommentData.prompt;
    this.ratingCategory = overallCommentData.ratingCategory;
    this.ratingComment = overallCommentData.ratingComment;
  }
}

export default OverallComment;
