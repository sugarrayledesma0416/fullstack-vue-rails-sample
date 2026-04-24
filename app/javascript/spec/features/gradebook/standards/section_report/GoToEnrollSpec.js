import { mount } from '@vue/test-utils';
import GoToEnroll from 'features/gradebook/standards/section_report/GoToEnroll';

describe('GoToEnroll.vue', () => {
  const mockEnrollmentPath = '/enroll';
  let wrapper;

  const createWrapper = (props = {}) => {
    return mount(GoToEnroll, {
      props: {
        newInstructorEnrollmentPath: mockEnrollmentPath,
        ...props,
      },
    });
  };

  beforeEach(() => {
    wrapper = createWrapper();
  });

  it('renders the component correctly', () => {
    expect(wrapper.exists()).toBe(true);
  });

  it('displays the correct message for no students', () => {
    const msgElm = wrapper.find('.test-no-students-msg');
    expect(msgElm.text()).toContain(
      'No students enrolled in this section yet. Go to Enroll to see your student data below.'
    );
  });

  it('renders the "Go to Enroll" link with the correct href', () => {
    const link = wrapper.find('.test-go-to-enroll-link');
    expect(link.attributes('href')).toBe(mockEnrollmentPath);
  });
});

