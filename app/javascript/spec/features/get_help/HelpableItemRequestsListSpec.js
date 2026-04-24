import { shallowMount } from '@vue/test-utils';
import HelpableItemRequestsList from 'features/get_help/HelpableItemRequestsList';
import StudentRequestForHelp from 'features/get_help/StudentRequestForHelp';
import InstructorHelpResponse from 'features/get_help/InstructorHelpResponse';

const injections = {
  metaData: {
    activityId: '46220',
    programId: '80',
    sectionId: '53',
    userType: 'Student',
  },
  requests: [
    {
      activity_id: 46220,
      activity_state: 'show',
      created_at: '2021-03-26T01:21:02-04:00',
      helpable_item_id: 'direction_line',
      helpable_item_type: null,
      id: 26,
      instructor_comment: 'Help Request Processed',
      instructor_name: 'Lolita Stracke',
      processed_at: '2021-03-26T03:06:09-04:00',
      program_id: 80,
      read_by_student: false,
      request_type: 'request_help',
      section_id: 53,
      status: 'submitted',
      student_comment: 'Direction Line Activity: 46220 Help Request.',
      student_name: 'Brando Kunde',
      user_id: 24,
    },
  ],
};

const props = {
  helpableItemId: 'direction_line',
};

const getWrapper = (options) => {
  return shallowMount(HelpableItemRequestsList, {
    props: options.props,
    global: {
      provide: options.injections,
    },
    attachTo: document.body,
  });
};

const options = { injections: injections, props: props };

describe('HelpableItemRequestsList', () => {
  let wrapper;

  beforeAll(() => {
    wrapper = getWrapper(options);
  });

  it('wrapper has help disclosure class', () => {
    expect(wrapper.attributes('class')).toContain(
      `js-help-disclosure-${injections.metaData.userType}-${props.helpableItemId}`
    );
  });

  it('mounts student disclosure component', () => {
    expect(wrapper.findAllComponents(StudentRequestForHelp)).toHaveLength(1);
  });

  it('does not mount instructor disclosure component', () => {
    expect(wrapper.findAllComponents(InstructorHelpResponse)).toHaveLength(0);
  });

  it('has button to View Help Request', () => {
    expect(wrapper.find('.js-help-request-header').text()).toBe('View Student Request(s)');
  });
});
