import { shallowMount } from '@vue/test-utils';
import Tooltip from 'features/gradebook/standards/section_report/Tooltip';

describe('Tooltip.vue', () => {
  let wrapper;
  const defaultProps = {
    categoryName: '',
    description: '',
    mode: 'show-standard',
    position: { left: 100, top: 200, topOffset: 10 },
    title: 'Sample Title',
  };

  const getWrapper = (props = {}) => {
    return shallowMount(Tooltip, {
      global: {
        stubs: {
          'vhl-assessment-count-icon-white': true,
        },
      },
      props: {
        ...defaultProps,
        ...props,
      },
    });
  };

  beforeEach(() => {
    wrapper = getWrapper();
  });

  describe('Rendering and structure', () => {
    it('renders the tooltip container with the correct base class', () => {
      expect(wrapper.classes()).toContain('tooltip');
    });

    it('applies the mode-specific class', () => {
      wrapper = getWrapper({ mode: 'show-activity-info' });
      expect(wrapper.classes()).toContain('mode--show-activity-info');
    });

    it('applies category-specific class', () => {
      const categories = [
        {
          name: 'Quizzes',
          expectedClass: 'category--quizzes',
        },
        {
          name: 'Unit Test',
          expectedClass: 'category--unit_test',
        },
        {
          name: 'Speaking and Writing Tests',
          expectedClass: 'category--speaking_and_writing_tests',
        },
      ];

      categories.forEach(({ name, expectedClass }) => {
        wrapper = getWrapper({ categoryName: name });
        expect(wrapper.classes()).toContain(expectedClass);
      });
    });

    it('computes the correct left value in style from position prop', () => {
      const expectedStyle = {
        left: '100px',
        top: '190px',
      };
      expect(wrapper.attributes('style')).toContain(`left: ${expectedStyle.left};`);
    });


    it('computes the correct top value with offset in style from position prop', () => {
      const expectedStyle = {
        left: '100px',
        top: '190px',
      };
      expect(wrapper.attributes('style')).toContain(`top: ${expectedStyle.top};`);
    });
  });

  describe('Content rendering', () => {
    it('renders the title in the tooltip header', () => {
      expect(wrapper.find('.test-header-text').text()).toBe(defaultProps.title);
    });

    it('renders the description in the tooltip body', () => {
      expect(wrapper.find('.test-tooltip-body').text()).toContain(defaultProps.description);
    });

    it('conditionally renders the assessment-counts icon when mode is "show-activity-info"', () => {
      wrapper = getWrapper({ mode: 'show-activity-info' });
      expect(wrapper.find('.test-assessment-counts-icon').exists()).toBeTruthy();
    });
  });
});
