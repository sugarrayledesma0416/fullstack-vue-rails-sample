// @ts-check

/**
 * @typedef {Object} DetailsData
 * @property {string} comment
 */

/**
 * Represents rating details.
 */
export class RatingDetailsModel {
  /**
   * @param {DetailsData} detailsData
   */
  constructor(detailsData) {
    if (detailsData) {
      this.comment = detailsData.comment;
    } else {
      this.comment = '';
    }
  }
}
