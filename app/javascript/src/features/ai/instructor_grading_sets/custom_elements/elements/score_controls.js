// @ts-check

import { registerCustomElement } from '../utils';

/**
 * Renders stylized score controls.
 */
export class ScoreControls extends HTMLElement {
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
      }

      .text {
        font-family: Open Sans, sans-serif;
        font-size: 1rem;
        font-weight: 400;
      }

      .title {
        margin: 0;
        line-height: 1.8;
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
      <h3 class="title  text">Overall Feedback</h3>
      <div class="controls  text">
        Total
        <slot></slot>
        ${this.#pointsPossible().outerHTML}
      </div>
    `;

    return wrapper;
  }

  /**
   * Renders the points possible for the question.  If, for some reason the points possible is
   * unavailable, this will return an empty span.
   * @return {HTMLSpanElement}
   */
  #pointsPossible() {
    const { pointsPossible } = this.dataset;
    const ele = document.createElement('span');
    ele.classList.add('points_possible');
    if (pointsPossible) ele.textContent = `/ ${pointsPossible}`;
    return ele;
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

registerCustomElement('score-controls', ScoreControls);
