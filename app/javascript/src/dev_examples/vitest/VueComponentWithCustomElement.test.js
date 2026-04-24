/**
 * @fileoverview
 * This file illustrates how to test a Vue component that contains a custom
 * element.
 *
 * In most cases, the typical approach is to stub the custom element via
 * VueTestUtils's Stubs feature.  This is because VueTestUtils does NOT
 * implement an actual DOM API.  Think of it as "shallow mounting" the custom
 * element by default.
 * @see: https://test-utils.vuejs.org/migration/#mocks-and-stubs-are-now-in-global
 *
 * However, in this example, we test the custom element as though it were
 * mounted in an actual browser. To do this, we mount the Vue component as if it
 * were a standalone Vue app.  We can then use vanilla DOM manipulation to
 * test the custom element.
 *
 * We can also query the Vue app itself, including triggering user interactions,
 * which requires waiting for the app to update, etc., which is out of scope for
 * this example.
 */

import { createApp } from 'vue';
import VueComponentWithCustomElement from './VueComponentWithCustomElement.vue';
import { MyCustomElement } from './custom_element.js';

let mountTarget;

describe('MyCustomElement', () => {
  beforeAll(() => {
    // Register the custom element globally
    customElements.define('my-custom-element', MyCustomElement);
  });

  beforeEach(() => {
    // Create a mount target for the component
    mountTarget = document.createElement('div');
    mountTarget.setAttribute('id', 'mount-target');
    document.body.appendChild(mountTarget);
  });

  afterEach(() => {
    // Clean up the mount target after each test
    if (mountTarget) {
      document.body.removeChild(mountTarget);
      mountTarget = null;
    }
  });

  it('renders the custom element', () => {
    const app = createApp(VueComponentWithCustomElement);
    app.mount(mountTarget);
    const customElement = mountTarget.querySelector('my-custom-element');
    expect(customElement).not.toBeNull();
    expect(customElement.shadowRoot).not.toBeNull();
  });

  it('renders the custom element with the correct content', () => {
    const app = createApp(VueComponentWithCustomElement);
    app.mount(mountTarget);
    const customElement = mountTarget.querySelector('my-custom-element');
    const header = customElement.shadowRoot.querySelector('h1');
    const paragraph = customElement.shadowRoot.querySelector('p');
    expect(header.textContent).toBe('Hello from MyCustomElement!');
    expect(paragraph.textContent).toBe('This is a custom web component.');
  });
});
