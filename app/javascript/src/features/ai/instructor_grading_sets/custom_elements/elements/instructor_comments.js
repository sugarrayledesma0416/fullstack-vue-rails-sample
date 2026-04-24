// @ts-check

import { registerCustomElement } from '../utils';

/**
 * Renders a textfield for instructor comments.
 */
class InstructorComments extends HTMLElement {
  /**
   * @constructor
   */
  constructor() {
    super();
  }

  /**
   * Returns a style element that applies to this element's shadow DOM.
   * @return {HTMLStyleElement}
   */
  #styles() {
    const style = document.createElement('style');
    style.textContent = `
      :host {
        display: block;
        margin-top: 0.7rem;
        width: 100%;
      }

      .textarea {
        border: thin solid #ccc;
        font-family: Open Sans, sans-serif;
        font-size: 1rem;
        height: 9.5rem;
        padding: 1rem;
        width: calc(100% - 2.1rem);
      }
    `;

    return style;
  }

  /**
   * Returns the HTML content for this element.
   * @return {HTMLTextAreaElement}
   */
  #html() {
    const textArea = document.createElement('textarea');
    textArea.classList.add('textarea');
    if (this.dataset.textareaName) {
      textArea.setAttribute('name', this.dataset.textareaName);
    }
    if (this.dataset.textareaId) {
      textArea.setAttribute('id', this.dataset.textareaId);
    }
    if (this.dataset.textareaValue) {
      textArea.textContent = this.dataset.textareaValue;
    }
    textArea.setAttribute('autocorrect', 'off');
    textArea.setAttribute('placeholder', 'Comments');
    textArea.setAttribute('spellcheck', 'false');
    return textArea;
  }

  /**
   * Fires when the element is added to the DOM.
   */
  connectedCallback() {
    this.attachShadow({ mode: 'open' });
    this.shadowRoot.appendChild(this.#styles());
    this.shadowRoot.appendChild(this.#html());
  }
}

registerCustomElement('instructor-comments', InstructorComments);
