/** @typedef {import('lit').LitElement} Lit.LitElement */
/** @typedef {import('lit').ReactiveController} Lit.ReactiveController */
/* eslint-disable-next-line max-len */
/** @typedef {import('lit').ReactiveControllerHost} Lit.ReactiveControllerHost */
/** @typedef {import('../../entities/action').Action.Name} Action.Name */
/** @typedef {import('../../entities/icon_collection').IconCollection} IconCollection.IconCollection */

/**
 * Implements common functionality used by all Action elements.
 *
 * @implements {Lit.ReactiveController}
 */
export class ActionController {
  static DEFAULT_CLICK_EVENT_TYPE = 'intranav_action.click';

  /**
   * @constructor
   * @param {Lit.ReactiveControllerHost} host - The host element.
   */
  constructor(host) {
    this.host = host;
    host.addController(this);
  }

  /**
   * Dispatches a custom event when an Action is clicked.
   */
  handleClick() {
    const{action, eventType} = this.host;
    const event = new CustomEvent(eventType, {
      bubbles: true,
      composed: true,
      detail: {
        index: action.id,
        action,
      },
    });
    this.host.dispatchEvent(event);
  }

  /**
   * Renders the action's icon.
   *
   * @param {Action.Name} name - The Action's name.
   * @return {Lit.SVGTemplateResult}
   */
  renderIcon(name) {
    /** @type {IconCollection.IconCollection} */
    const { icons } = this.host;
    switch (name) {
    case 'listen-repeat':
      return icons.listenRepeat();
    case 'match':
      return icons.match();
    case 'say-it':
      return icons.sayIt();
    case 'diagnostics':
      return icons.diagnostics();
    case 'video-tutorial':
      return icons.interactiveVideo();
    default:
      throw new RangeError('Action name is invalid.');
    }
  }

  /**
   * Formats a given string for screen readers so that they do not pronounce
   * individual letters, e,g, "say I T" for "say-it", etc.
   *
   * @param {string} string - The string to format.
   * @return {string} A screen reader friendly string.
   */
  formatStringForScreenReaders(string) {
    const lowercase = string.toLocaleLowerCase();
    const withoutHyphens = lowercase.replace('-', ' ');
    return withoutHyphens;
  }
}

