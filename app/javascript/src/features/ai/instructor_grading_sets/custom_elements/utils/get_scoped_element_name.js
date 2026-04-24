// @ts-check

import { CUSTOM_ELEMENT_NAMESPACE } from '../constants.js';

/**
 * Quality of life function that returns the namespaced name of the provided custom element.  This
 * allows the developer to refer to a custom element by its feature level name rather than its
 * globally registered name.
 * @param {string} name - The name of the custom element, e.g. "cancel-button".
 * @return {string} The name of the custom element, e.g. "vhl-feature-cancel-button".
 */
export function getScopedElementName(name) {
  return `${CUSTOM_ELEMENT_NAMESPACE}-${name}`;
}
