// @ts-check

import { registerCustomElement } from '../utils';

/**
 * Renders stylized score controls.
 */
export class StarsIcon extends HTMLElement {
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
        display: inline-block;
      }

      .icon-path {
        stroke: var(--icon-color, #000);
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
      <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
        <g clip-path="url(#clip0_215_172)">
        <path class="icon-path" d="M5.41675 10.8333L6.07046 12.1407C6.2917 12.5832 6.40233 12.8044 6.55011 12.9962C6.68124 13.1663 6.83375 13.3188 7.00388 13.4499C7.19559 13.5977 7.41684 13.7083 7.85932 13.9296L9.16675 14.5833L7.85932 15.237C7.41684 15.4582 7.19559 15.5689 7.00388 15.7167C6.83375 15.8478 6.68124 16.0003 6.55011 16.1704C6.40233 16.3621 6.2917 16.5834 6.07046 17.0259L5.41675 18.3333L4.76303 17.0259C4.54179 16.5834 4.43117 16.3621 4.28339 16.1704C4.15225 16.0003 3.99974 15.8478 3.82962 15.7167C3.6379 15.5689 3.41666 15.4582 2.97418 15.237L1.66675 14.5833L2.97418 13.9296C3.41666 13.7083 3.6379 13.5977 3.82962 13.4499C3.99974 13.3188 4.15225 13.1663 4.28339 12.9962C4.43117 12.8044 4.54179 12.5832 4.76303 12.1407L5.41675 10.8333Z" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        <path class="icon-path" d="M12.5001 1.66663L13.4823 4.22031C13.7173 4.83133 13.8348 5.13685 14.0175 5.39383C14.1795 5.62159 14.3785 5.82058 14.6062 5.98253C14.8632 6.16526 15.1687 6.28276 15.7797 6.51777L18.3334 7.49996L15.7797 8.48214C15.1687 8.71715 14.8632 8.83466 14.6062 9.01739C14.3785 9.17934 14.1795 9.37833 14.0175 9.60609C13.8348 9.86307 13.7173 10.1686 13.4823 10.7796L12.5001 13.3333L11.5179 10.7796C11.2829 10.1686 11.1654 9.86307 10.9827 9.60609C10.8207 9.37833 10.6217 9.17934 10.394 9.01739C10.137 8.83466 9.83146 8.71715 9.22043 8.48214L6.66675 7.49996L9.22043 6.51777C9.83146 6.28276 10.137 6.16526 10.3939 5.98253C10.6217 5.82058 10.8207 5.62159 10.9827 5.39383C11.1654 5.13685 11.2829 4.83133 11.5179 4.22031L12.5001 1.66663Z" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </g>
        <defs>
        <clipPath id="clip0_215_172">
        <rect width="20" height="20" fill="white"/>
        </clipPath>
        </defs>
      </svg>
    `;

    return wrapper;
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

registerCustomElement('stars-icon', StarsIcon);
