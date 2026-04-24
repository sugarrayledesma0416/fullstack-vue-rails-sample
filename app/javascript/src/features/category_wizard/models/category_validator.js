/**
 * This class has methods to validate category fields.
 */
export default class CategoryValidator {
/**
 * @typedef {
 *  import('features/course_wizard/services/course_serializer.js').CategoryObject
 * } CategoryObject
 */

  /**
   * @constructor
   * @param {CategoryObject} category - category model object
   */
  constructor(category) {
    this.category = category;
  }

  /**
   * checks for the type of error and returns it's corresponding message
   * @param {number} step - index of Add Category step
   * @param {Array.<CategoryObject>} categories
   * @return {errorDataType} - object that contains its value and error message.
   */
  isStepInValid(step, categories) {
    let res;

    switch (step) {
    case 0:
      res = this.hasErrorInCategoryName(categories).value;
      break;
    case 1:
      res = this.hasErrorInCategoryWeight().value;
      break;
    case 6:
      res = this.hasErrorInPenaltyPercent().value;
      break;
    default:
      res = false;
    }
    return res;
  }

  /**
   * checks for error in category name and returns it's corresponding message
   * @param {Array.<CategoryObject>} categories
   * @return {errorDataType} - object that contains its value and error message.
   */
  hasErrorInCategoryName(categories) {
    let msg = '';
    let value = false;
    if (!this.category.name) {
      msg = 'This is a required field';
      value = true;
    } else if (this.isCategoryNameUsed(categories)) {
      return {
        msg: 'This category name is already in use',
        value: true,
      };
    }
    return { msg, value };
  }

  /**
   * checks for error in category name and returns it's corresponding message
   * @return {errorDataType} - object that contains its value and error message.
   */
  hasErrorInCategoryWeight() {
    let msg = '';
    let value = false;
    const weight = parseInt(this.category.weightingPercent);

    if (isNaN(weight)) {
      msg = 'Category weight is required';
      value = true;
    } else if (!(weight >=0 && weight <=100)) {
      msg = 'Category weight must be between 0 and 100';
      value = true;
    }
    return { msg, value };
  }

  /**
   * checks for error in category penalty percent and returns it's corresponding message
   * @return {errorDataType} - object that contains its value and error message.
   */
  hasErrorInPenaltyPercent() {
    let msg = '';
    let value = false;
    if (this.category.lateWorkPenalty !== 'none') {
      const penaltyPercent = parseInt(this.category.penaltyPercent);

      if (isNaN(penaltyPercent) || !(penaltyPercent >=0 && penaltyPercent <=100)) {
        msg = 'A valid number is required.';
        value = true;
      }
    }
    return { msg, value };
  }
  /**
   * @private
   * This method checks if the current category name is present in the course
   * categories.
   * @param {Array.<CategoryObject>} categories
   * @return {boolean}
   */
  isCategoryNameUsed(categories) {
    return categories.some((category) => {
      return !category._destroy && category.name === this.category.name;
    });
  }
}
