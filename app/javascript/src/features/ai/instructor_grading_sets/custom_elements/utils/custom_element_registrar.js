// @ts-check

import { getScopedElementName } from './get_scoped_element_name.js';

/**
 * @param {string} name - The name of the custom element, e.g. "cancel-button".
 * @param {CustomElementConstructor} constructor - The constructor function for the custom element.
 */
export function registerCustomElement(name, constructor) {
  customElements.define(getScopedElementName(name), constructor);
}
