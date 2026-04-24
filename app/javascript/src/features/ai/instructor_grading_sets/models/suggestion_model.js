// @ts-check

/**
 * @typedef {Object} SuggestionData
 * @property {boolean} accepted
 * @property {boolean} edited
 * @property {string} error_explanation
 * @property {number} id
 * @property {string} incorrect_text
 * @property {number | null} incorrect_text_begin_offset
 * @property {number | null} incorrect_text_end_offset
 * @property {number | null} rating_category_id
 * @property {string | null} rating_comment
 * @property {boolean} rejected
 */

/**
 * Represents a single suggestion.
 */
export class SuggestionModel {
  /**
   * @param {SuggestionData} suggestionData
   */
  constructor(suggestionData) {
    this.accepted = suggestionData.accepted;
    this.edited = suggestionData.edited;
    this.errorExplanation = suggestionData.error_explanation;
    this.id = suggestionData.id;
    this.incorrectText = suggestionData.incorrect_text;
    this.incorrectTextBeginOffset = suggestionData.incorrect_text_begin_offset;
    this.incorrectTextEndOffset = suggestionData.incorrect_text_end_offset;
    this.ratingCategoryId = suggestionData.rating_category_id;
    this.ratingComment = suggestionData.rating_comment;
    this.rejected = suggestionData.rejected;
  }

  /**
   * Marks this Suggestion as accepted.
   */
  accept() {
    this.accepted = true;
    this.rejected = false;
  }

  /**
   * Marks this Suggestion as rejected.
   */
  reject() {
    this.accepted = false;
    this.rejected = true;
    this.edited = false;
  }

  /**
   * Removes a suggestion.
   */
  remove() {
    this.accepted = false;
    this.rejected = false;
    this.edited = false;
  }
}
