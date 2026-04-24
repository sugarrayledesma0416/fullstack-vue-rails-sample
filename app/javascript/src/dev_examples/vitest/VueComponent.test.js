/**
 * @fileoverview
 * This file illustrates how to test a basic Vue component with Vitest.
 */

import VueComponent from './VueComponent.vue';
import { mount } from '@vue/test-utils';

describe('VueComponent', () => {
  it('renders the component', () => {
    const wrapper = mount(VueComponent, {
      props: {
        name: 'World'
      }
    });
    expect(wrapper.exists()).toBe(true);
  });

  it('displays the correct message', () => {
    const wrapper = mount(VueComponent, {
      props: {
        name: 'Vue'
      }
    });
    expect(wrapper.text()).toContain('Hello, Vue!');
  });
});
