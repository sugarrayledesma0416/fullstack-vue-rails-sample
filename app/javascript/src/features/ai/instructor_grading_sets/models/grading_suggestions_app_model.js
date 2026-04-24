// @ts-check

import { SuggestionModel } from './suggestion_model';
/** @typedef {import('./suggestion_model').SuggestionData} SuggestionData */

import { OverallCommentModel } from './overall_comment_model';
/** @typedef {import('./overall_comment_model').OverallCommentData} OverallCommentData */

import { RatingDetailsModel } from './rating_details_model';
/** @typedef {import('./rating_details_model').DetailsData} RatingDetailsData */

/**
 * @typedef {Object} SuggestionJob
 * @property {number} attempt_id
 * @property {string} question_label
 * @property {'completed'|'failed'|'in_progress'} status
 */

/**
 * @typedef {Object} GradingSuggestionData
 * @property {string} feedbackElementId
 * @property {string | number} id
 * @property {Object | undefined} overallComment
 * @property {string} overallCommentElement
 * @property {string} overallCommentName
 * @property {Array<string>} ratingCategories
 * @property {Object | undefined} ratingDetails
 * @property {number} defaultRatingCategoryId
 * @property {Array<SuggestionData>} suggestions
 * @property {SuggestionJob} suggestionJob
 * @property {string} suggestionsElementName
 */

/**
 * Represents a single suggestion.
 */
export class GradingSuggestionsAppModel {
  /**
   * @param {GradingSuggestionData} suggestionData
   */
  constructor(suggestionData) {
    this.feedbackElementId = suggestionData.feedbackElementId;
    this.id = suggestionData.id;
    this.overallComment = suggestionData.overallComment ?
      new OverallCommentModel(suggestionData.overallComment) : undefined;
    this.overallCommentElement = suggestionData.overallCommentElement;
    this.overallCommentName = suggestionData.overallCommentName;
    this.ratingCategories = suggestionData.ratingCategories;
    /** @type {Array<SuggestionModel>} */
    this.suggestions = this._buildSuggestions(suggestionData.suggestions);
    this.suggestionJob = suggestionData.suggestionJob;
    this.suggestionsElementName = suggestionData.suggestionsElementName;
    this.showFlagSuggestionsDialog = false;
    this.ratingDetails = new RatingDetailsModel(suggestionData.ratingDetails);
    this.defaultRatingCategoryId = suggestionData.defaultRatingCategoryId;
  }

  /**
   * True if the suggestionJob completed but found no errors in the response.
   * Returns false if no suggestionJob exists, which will be the case for
   * suggestions generated before the job tracking code was deployed.
   * @return {boolean}
   */
  foundNoSuggestions() {
    return (
      this.suggestions.length == 0 &&
      (this.suggestionJob && this.suggestionJob.status == 'completed')
    );
  }

  /**
   * @param {Array<SuggestionData>} suggestionData
   * @return {Array<SuggestionModel>}
   */
  _buildSuggestions(suggestionData) {
    return suggestionData.map((suggestion) => new SuggestionModel(suggestion));
  }

  /**
   * @param {number} suggestionId
   * @return {SuggestionModel | undefined}
   */
  getSuggestion(suggestionId) {
    return this.suggestions.find((suggestion) => suggestion.id === suggestionId);
  }
}
