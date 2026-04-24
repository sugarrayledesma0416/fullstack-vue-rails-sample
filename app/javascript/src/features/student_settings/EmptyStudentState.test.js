import { mount } from '@vue/test-utils';
import EmptyStudentState from './EmptyStudentState.vue';

describe('EmptyStudentState', () => {
  let wrapper;
  const defaultProps = {
    rostering: false,
    rosterUrl: '/roster'
  };

  beforeEach(() => {
    wrapper = mount(EmptyStudentState, {
      props: defaultProps
    });
  });

  describe('rendering', () => {
    it('renders the no students message', () => {
      expect(wrapper.text()).toContain('No students enrolled');
    });

    it('renders the roster link when not using LMS rostering', () => {
      const link = wrapper.find('a');
      expect(link.text()).toBe('Roster');
      expect(link.attributes('href')).toBe('/roster');
    });

    it('renders the LMS sync message when using rostering', async () => {
      await wrapper.setProps({ rostering: true });
      expect(wrapper.text()).toContain('Students will display here once they sync.');
    });

    it('does not render the roster link when using LMS rostering', async () => {
      await wrapper.setProps({ rostering: true });
      expect(wrapper.find('a').exists()).toBe(false);
    });
  });

  describe('props validation', () => {
    it('requires rostering prop', () => {
      expect(EmptyStudentState.props.rostering.required).toBe(true);
    });

    it('requires rosterUrl prop', () => {
      expect(EmptyStudentState.props.rosterUrl.required).toBe(true);
    });
  });
});
