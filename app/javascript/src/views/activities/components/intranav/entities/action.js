/* eslint-disable max-len */
/**
 * @typedef {'listen-repeat' | 'match' | 'say-it' | 'video-tutorial' | 'diagnostic'} Action.Name - The action's
 * name.
 */
/* eslint-enable */

/**
 * @typedef {string} Action.Label - The action's label.
 */

/**
 * @typedef {'navigable' | 'current' | 'disabled' } Action.State - The current
 * state of the action.
 */

/**
 * @typedef {string | number} Action.Id - An identifier for the action.
 */

/**
 * Represents a single Action as used by the Intranav.
 *
 * @property {Action.Name} name - The Action's name.
 * @property {Action.Label} label - The Action's label.
 * @property {Action.State} state - The Action's current state.
 * @property {Action.Id} id - The Action's identifier.
 * its siblings.
 */
export class Action {
  /**
   * @constructor
   * @param {Action.Name} name - The Action's name.
   * @param {Action.Label} label - The Action's label.
   * @param {Action.State} state - The Action's current state.
   * @param {Action.Id} id - An identifier for the Action.
   */
  constructor(name, label, state, id) {
    this.name = this._validateName(name);
    this.label = this._validateLabel(label);
    this.state = this._validateState(state);
    this.id = this._validateId(id);
  }

  /**
   * Validates the name provided to the constructor.
   *
   * @param {Action.Name} name - The state passed to the constructor.
   * @return {Action.Name} The name, if valid.
   * @private
   */
  _validateName(name) {
    const nameType = typeof name;
    if (nameType !== 'string') {
      throw new TypeError(`name must be of type string, got ${nameType}`);
    }
    switch (name) {
    case 'listen-repeat':
      break;
    case 'match':
      break;
    case 'say-it':
      break;
    case 'video-tutorial':
      break;
    case 'diagnostic':
      break;
    default:
      throw new RangeError(`Invalid name, got ${name}`);
    }
    return name;
  }

  /**
   * Validates the label provided to the constructor.
   *
   * @param {Action.Label} label - The label passed to the constructor.
   * @return {Action.Label} The label, if valid.
   * @private
   */
  _validateLabel(label) {
    const labelType = typeof label;
    if (labelType !== 'string') {
      throw new TypeError(`label must be of type string, got ${labelType}`);
    }
    return label;
  }

  /**
   * Validates the state that was passed to the constructor.
   *
   * @param {Action.State} state - The state that was passed to the
   * constructor.
   * @return {Action.State} The state, if valid.
   * @private
   */
  _validateState(state) {
    const stateType = typeof state;
    if (stateType !== 'string') {
      throw new TypeError(`state must be of type string, got ${stateType}`);
    }
    switch (state) {
    case 'disabled':
      break;
    case 'current':
      break;
    case 'navigable':
      break;
    default:
      throw new RangeError(
        `state can only be "navigable", "current", or "disabled", got ${state}`
      );
    }
    return state;
  }

  /**
   * Validates the id that was passed to the constructor.
   *
   * @param {Action.Id} id - The id to valdiate.
   * @return {Action.Id} The id, if valid.
   * @private
   */
  _validateId(id) {
    const idType = typeof id;
    if (idType !== 'string' && idType !== 'number') {
      throw new TypeError(`id must be of type string or number, got ${idType}`);
    }
    return id;
  }
}

