// @ts-check

/**
 * @fileoverview
 * Vitest provides an API that mimics a native browser window (via the "jsdom"
 * package.)  This file illustrates how to test a custom element, which relies
 * on the DOM APIs to function.
 */

import { MyCustomElement } from './custom_element.js';

describe('MyCustomElement', () => {
  /* @type {MyCustomElement} */
  let element = document.createElement('my-custom-element');

  beforeAll(() => {
    // Define the custom element before running tests.
    customElements.define('my-custom-element', MyCustomElement);
  });

  beforeEach(() => {
    // Create a new instance of the custom element before each test.
    element = document.createElement('my-custom-element');
    document.body.appendChild(element);
  });

  afterEach(() => {
    // Clean up the document after each test.
    document.body.removeChild(element);
  });

  it('should be defined', () => {
    expect(element).toBeDefined();
  });

  it('should attach a shadow DOM', () => {
    expect(element.shadowRoot).not.toBeNull();
  });

  it('should render content in the shadow DOM', () => {
    if (element.shadowRoot) {
      const heading = element.shadowRoot.querySelector('h1');
      const paragraph = element.shadowRoot.querySelector('p');

      if (heading && paragraph) {
        expect(heading.textContent).toBe('Hello from MyCustomElement!');
        expect(paragraph.textContent).toBe('This is a custom web component.');
      }
    }
  });
});

