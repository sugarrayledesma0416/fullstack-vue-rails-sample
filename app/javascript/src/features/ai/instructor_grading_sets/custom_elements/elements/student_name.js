// @ts-check

import { registerCustomElement } from '../utils';

/**
 * Renders stylized score controls.
 */
export class StudentName extends HTMLElement {
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
      .wrapper {
        display: flex;
        flex-wrap: wrap;
        justify-content: space-between;
        padding: 1rem 0;
      }

      .text {
        font-family: Open Sans, sans-serif;
        font-size: 1rem;
        font-weight: 400;
      }

      .name {
        margin: 0;
      }
    `;
    return style;
  }

  /**
   * Returns the HTML content for this element.
   * @return {HTMLDivElement}
   */
  #html() {
    const wrapper = document.createElement('div');
    wrapper.classList.add('wrapper');

    wrapper.innerHTML = `
      <h3 class="name  text">${this.#name()}</h3>
      <slot></slot>
    `;

    return wrapper;
  }

  /**
   * Conditionally renders the student's name or default text.
   * @return {string}
   */
  #name() {
    const name = this.dataset.studentName;
    if (name) {
      return name;
    }
    return 'Student Name';
  }

  /**
   * Called when the element is added to the DOM.
   */
  connectedCallback() {
    const shadow = this.attachShadow({ mode: 'open' });
    shadow.appendChild(this.#styles());
    shadow.appendChild(this.#html());
  }
}

registerCustomElement('student-name', StudentName);
