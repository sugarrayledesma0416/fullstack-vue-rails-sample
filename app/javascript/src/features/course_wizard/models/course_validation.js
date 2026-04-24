// @ts-check

/**
 * @typedef Options
 * @property {Status} status - The validation's status.
 * @property {string} description - A description of the validation, used for
 * explaining the validation to the user.
 * @property {string} alias - A brief alias for describing what the validation
 * is for, used to help find a validation amongst a collection of other
 * validations.
 * @property {ErrorHandler} errorHandler
 */

/**
 * @typedef {(message: string) => any} ErrorHandler

/**
 * @typedef {'invalid' | 'warning' | 'valid'} Status
 */

/**
 * Stores the result of a single validation check.
 */
export class CourseValidation {
  /**
   * @param {Options} options Options for creating the validation.
   * Empty fields will be populated with default values.
   */
  constructor(options) {
    const { alias, description, status, errorHandler } = options;
    if (typeof errorHandler === 'function') {
      this.errorHandler = errorHandler;
    } else {
      this.errorHandler = this.defaultErrorHandler;
    }
    this.validateOptions(options);
    this._alias = alias;
    this._description = description;
    this._status = status;
  }

  /**
   * @private
   * @param {string} errorMessage
   */
  defaultErrorHandler(errorMessage) {
    console.error(errorMessage);
  }

  /**
   * @private
   * @param {Options} options
   */
  validateOptions(options) {
    const { alias, description, status } = options;
    this.validateAlias(alias);
    this.validateStatus(status);
    this.validateDescription(description, status);
  }

  /**
   * @private
   * @param {string} alias
   */
  validateAlias(alias) {
    if (typeof alias !== 'string' || alias.length === 0) {
      this.errorHandler(`Alias of "${alias}" is not supported.`);
    }
  }

  /**
   * @private
   * @param {Status} status
   */
  validateStatus(status) {
    /* @type {Array.<Status>} */
    const validStatus = ['invalid', 'warning', 'valid'];
    if (!validStatus.includes(status)) {
      this.errorHandler(`Status of "${status}" is not supported.`);
    }
  }

  /**
   * @private
   * @param {string} description
   * @param {Status} status
   */
  validateDescription(description, status) {
    const requiresDescription = this.statusRequiresDescription(status);
    const hasDescription = this.hasDescription(description);
    if (requiresDescription && !hasDescription) {
      this.errorHandler(
        `Options with status: "${status}" requires a description.`);
    }
  }

  /**
   * @private
   * @param {Status} status
   * @return {boolean} True if the status requires a description.
   */
  statusRequiresDescription(status) {
    const requiresDescription = ['invalid', 'warning'];
    return requiresDescription.includes(status);
  }

  /**
   * @private
   * @param {string} description
   * @return {boolean} True if the description is a valid string.
   */
  hasDescription(description) {
    const result = typeof description === 'string' && description.length;
    return result ? true : false;
  }

  /**
   * @return {string}
   */
  get alias() {
    return this._alias;
  }

  /**
   * @return {string | null}
   */
  get description() {
    return this._description;
  }

  /**
   * @return {Status}
   */
  get status() {
    return this._status;
  }
}
