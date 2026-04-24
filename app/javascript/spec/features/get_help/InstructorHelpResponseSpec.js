import { mount } from '@vue/test-utils';
import InstructorHelpResponse from 'features/get_help/InstructorHelpResponse';
import ZonedDateTime from 'shared/zoned_date_time';

VHL = { Music: { V1: {}}};

VHL.Music.V1.Disclosure = class Disclosure {
  constructor() {}
  toggle() {}
};

const props = {
  helpableItemId: 'direction_line',
};

const injections = {
  metaData: {
    activityId: '46220',
    programId: '80',
    sectionId: '53',
    userType: 'Instructor',
  },
  requests: [
    {
      activity_id: 46220,
      activity_state: 'show',
      created_at: '2021-03-26T01:21:02-04:00',
      helpable_item_id: 'direction_line',
      helpable_item_type: null,
      id: 26,
      instructor_comment: 'Help Request Processed.',
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

const opts = { injections: injections, props: props };

const getWrapper = (opts) => {
  return mount(InstructorHelpResponse, {
    global: {
      provide: opts.injections,
    },
    props: opts.props,
  });
};

describe('InstructorHelpResponse', () => {
  describe('I can see common help request information.', () => {
    let wrapper;
    const request = injections.requests[0];

    beforeEach(() => {
      wrapper = getWrapper(opts);
    });

    it('check if wrapper exists', () => {
      expect(wrapper.exists()).toBeTruthy();
    });

    it('has name of the student', () => {
      expect(wrapper.get('.test-student-name').text()).toBe(request.student_name);
    });

    it('has comment of the student', () => {
      expect(wrapper.get('.test-student-comment-text').text()).toBe(request.student_comment);
    });

    it('escapes the html tags inserted by the student', () => {
      request.student_comment = '<script>Do something</script>';
      wrapper = getWrapper(opts);
      expect(wrapper.get('.test-student-comment-text').wrapperElement.innerHTML).toBe(
        '&lt;script&gt;Do something&lt;/script&gt;'
      );
    });

    it('adds spans with the zh lang attribute if chinese characters are present', () => {
      request.student_comment = 'Chinese characters follow 一年级 1984年';
      wrapper = getWrapper(opts);
      expect(wrapper.get('.test-student-comment-text').wrapperElement.innerHTML).toBe(
        'Chinese characters follow <span lang="zh">一年级 1984年</span>'
      );
    });

    it('has request submitted date', () => {
      expect(
        wrapper.findAll('[data-content-type=\'request_submitted_date\']')[0].text()
      ).toBe(new ZonedDateTime(request.created_at).formattedDate());
    });

    it('has request submitted time', () => {
      expect(
        wrapper.findAll('[data-content-type=\'request_submitted_date\']')[1].text()
      ).toBe(new ZonedDateTime(request.created_at).formattedTime());
    });
  });

  describe('When instructor comment is present', () => {
    let wrapper;
    const request = injections.requests[0];

    beforeEach(() => {
      wrapper = getWrapper(opts);
    });

    it('has name of the instructor', () => {
      expect(wrapper.get('.test-instructor-name').text()).toBe(request.instructor_name);
    });

    it('has response of the instructor', () => {
      expect(wrapper.get('.test-instructor-comment-text').text()).toBe(request.instructor_comment);
    });

    it('escapes the html tags inserted by the instructor', () => {
      request.instructor_comment = '<script>Do something</script>';
      wrapper = getWrapper(opts);
      expect(wrapper.get('.test-instructor-comment-text').wrapperElement.innerHTML).toBe(
        '&lt;script&gt;Do something&lt;/script&gt;'
      );
    });

    it('adds spans with the zh lang attribute if chinese characters are present', () => {
      request.instructor_comment = 'Chinese characters follow 一年级 1984年';
      wrapper = getWrapper(opts);
      expect(wrapper.get('.test-instructor-comment-text').wrapperElement.innerHTML).toBe(
        'Chinese characters follow <span lang="zh">一年级 1984年</span>'
      );
    });

    it('has request processed date', () => {
      expect(
        wrapper.findAll('[data-content-type=\'request_responded_date\']')[0].text()
      ).toBe(new ZonedDateTime(request.processed_at).formattedDate());
    });

    it('has request processed time', () => {
      expect(
        wrapper.findAll('[data-content-type=\'request_responded_date\']')[1].text()
      ).toBe(new ZonedDateTime(request.processed_at).formattedTime());
    });

    it('edit comment area is not visible', () => {
      expect(
        wrapper.get(`.js-instructor-comment-area-${request.id}`).isVisible()
      ).toBe(false);
    });
  });

  describe('when "Edit" clicked', () => {
    let wrapper;
    const request = injections.requests[0];
    let editButton;

    beforeEach(() => {
      wrapper = getWrapper(opts);
      editButton = wrapper.get(`.js-edit-request-${request.id}`);
    });

    it('edit comment area is visible', async () => {
      await editButton.trigger('click');
      expect(
        wrapper.find(`.js-instructor-comment-area-${request.id}`).isVisible()
      ).toBe(true);
    });
  });
});
