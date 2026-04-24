import { Action } from '../../entities/action';

/** @typedef {import('lit').LitElement} Lit.LitElement */
/** @typedef {import('lit').ReactiveController} Lit.ReactiveController */
/* eslint-disable-next-line max-len */
/** @typedef {import('lit').ReactiveControllerHost} Lit.ReactiveControllerHost */

/**
 * Implements common functionality used by all variants of the Intranav.
 *
 * @implements {Lit.ReactiveController}
 */
export class IntranavController {
  /**
   * @constructor
   * @param {Lit.ReactiveControllerHost} host - The host element.
   */
  constructor(host) {
    this.host = host;
    host.addController(this);
  }

  /**
   * Converts a JSON string array of Actions to an array of Action entities.
   *
   * Throws an exception if an Action is created with invalid data.
   * @param {string | null} value - A JSON string array of Actions to convert.
   * @return {Array<Action>} The resulting array of Action entities.
   */
  static actionsConverter(value) {
    /** @type {Array<Action>} */
    let actions = [];
    if (value !== null && value.length) {
      actions = IntranavController.convertJSONToActions(value);
    }
    return actions;
  }

  /**
   * Parses a JSON string array of Actions to an array of Action entities and
   * returns the resulting array.
   *
   * @param {string} json - A JSON string array of actions.
   * @return {Array<Action>} An array of action entities.
   */
  static convertJSONToActions(json) {
    /** @type {Array<Action>} */
    const actionEntities = [];
    const parsed = JSON.parse(json);
    for (let i = 0; i < parsed.length; i++) {
      const action = parsed[i];
      const { name, label, state } = action;
      actionEntities.push(new Action(name, label, state, i));
    }
    return actionEntities;
  }
}

