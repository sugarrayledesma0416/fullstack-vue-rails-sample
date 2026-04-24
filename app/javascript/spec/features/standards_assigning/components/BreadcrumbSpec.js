import { shallowMount } from '@vue/test-utils';
import Breadcrumb from 'features/standards_assigning/components/Breadcrumb.vue';
import { createTestingPinia } from '@pinia/testing';

describe('Breadcrumb.vue', () => {
  let wrapper;

  function getWrapper() {
    return shallowMount(Breadcrumb, {
      global: {
        plugins: [
          createTestingPinia({
            stubActions: false,
          }),
        ],
      },
      props: {
        availableGradeLevels: [
          { grade: '1', display_grade: 'Grade 1' },
          { grade: '2', display_grade: 'Grade 2' },
        ],
      },
    });
  }

  beforeEach(() => {
    wrapper = getWrapper();
    wrapper.vm.store.selectedStandardSet = { key: 'Math Standards', value: 'Math Standards - Grade 1' };
  });

  afterEach(() => {
    wrapper.unmount();
    jest.clearAllMocks();
  });

  describe('Rendering', () => {
    it('renders the breadcrumb container', () => {
      expect(wrapper.find('sl-breadcrumb').exists()).toBeTruthy();
    });

    it('renders the first breadcrumb item with the correct text', () => {
      const firstBreadcrumbItem = wrapper.find('.test-breadcrumb-item');
      expect(firstBreadcrumbItem.exists()).toBeTruthy();
      expect(firstBreadcrumbItem.get('.test-breadcrumb-standard-set-txt').text()).toBe('Math Standards');
    });

    it('renders the second breadcrumb item with the correct grade level', () => {
      const secondBreadcrumbItem = wrapper.find('.test-breadcrumb-subitem');
      expect(secondBreadcrumbItem.exists()).toBeTruthy();
      expect(
        secondBreadcrumbItem.get('.test-breadcrumb-grade-level-txt').text()
      ).toBe('Grades 1 - 2');
    });

    it('renders the tooltip with the correct content', () => {
      const tooltip = wrapper.find('sl-tooltip');
      expect(tooltip.exists()).toBeTruthy();
      expect(tooltip.attributes('content')).toBe('Math Standards - Grade 1');
    });
  });

  describe('Functionality', () => {
    it('computes shortStandardSetText correctly', () => {
      expect(wrapper.vm.shortStandardSetText).toBe('Math Standards');
    });

    it('emits reset-from-breadcrumb event when the first breadcrumb item is clicked', async () => {
      const firstBreadcrumbItem = wrapper.find('.breadcrumb-item');
      await firstBreadcrumbItem.trigger('click');
      expect(wrapper.emitted('reset-from-breadcrumb')).toBeTruthy();
      expect(wrapper.emitted('reset-from-breadcrumb').length).toBe(1);
    });
  });
});
