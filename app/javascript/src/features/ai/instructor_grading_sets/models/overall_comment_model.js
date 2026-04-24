// @ts-check

/**
 * @typedef {Object} OverallCommentData
 * @property {boolean} accepted
 * @property {string} explanation
 * @property {number} id
 * @property {string} overall_comment
 * @property {number | null} rating_category_id
 * @property {string | null} rating_comment
 * @property {boolean} rejected
 */

/**
 * Represents a overall comment.
 */
export class OverallCommentModel {
  /**
   * @param {OverallCommentData} overallCommentData
   */
  constructor(overallCommentData) {
    this.accepted = overallCommentData.accepted;
    this.edited = false;
    this.explanation = overallCommentData.explanation;
    this.id = overallCommentData.id;
    this.overallComment = overallCommentData.overall_comment;
    this.ratingCategoryId = overallCommentData.rating_category_id;
    this.ratingComment = overallCommentData.rating_comment;
    this.rejected = overallCommentData.rejected;
    this.defaultComment = `${this.overallComment}. ${this.explanation}`;
  }

  /**
   * Marks this Suggestion as accepted.
   */
  accept() {
    this.accepted = true;
    this.rejected = false;
  }

  /**
   * Compares the provided comment with the default comment.  If the two are different, the comment
   * is marked as edited.
   * @param {string} comment
   * @return {boolean} - True if the comment is different from the default comment.
   */
  validateEdit(comment) {
    comment == this.defaultComment ? this.edited = false : this.edited = true;
    return this.edited;
  }

  /**
   * Marks this Suggestion as rejected.
   */
  reject() {
    this.accepted = false;
    this.edited = false;
    this.rejected = true;
  }

  /**
   * Removes a suggestion.
   */
  remove() {
    this.accepted = false;
    this.edited = false;
    this.rejected = false;
  }
}
