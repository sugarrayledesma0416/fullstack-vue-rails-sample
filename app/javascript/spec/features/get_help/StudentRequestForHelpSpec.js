import { mount } from '@vue/test-utils';
import StudentRequestForHelp from 'features/get_help/StudentRequestForHelp';
import ZonedDateTime from 'shared/zoned_date_time';

VHL = { Music: { V1: {}}};

VHL.Music.V1.Disclosure = class Disclosure {
  constructor() {}
  toggle() {}
};

const getWrapper = (opts) => {
  return mount(StudentRequestForHelp, {
    global: {
      provide: opts.injections,
    },
    props: opts.props,
  });
};

describe('StudentRequestForHelp when Instructor response is not present', () => {
  const props = {
    helpableItemId: 'direction_line',
  };

  const injections = {
    metaData: {
      activityId: '46224',
      programId: '80',
      sectionId: '53',
      userType: 'Student',
    },
    requests: [
      {
        activity_id: 46224,
        activity_state: 'show',
        created_at: '2021-03-26T01:36:54-04:00',
        helpable_item_id: 'question_01_prompt',
        helpable_item_type: null,
        id: 41,
        instructor_comment: null,
        instructor_name: null,
        processed_at: null,
        program_id: 80,
        read_by_student: false,
        request_type: 'request_help',
        section_id: 53,
        status: 'submitted',
        student_comment: 'Doubt over Direction Line',
        student_name: 'Brando Kunde',
        user_id: 24,
      },
    ],
  };

  const opts = { injections: injections, props: props };

  describe('I can see common help request information.', () => {
    let wrapper;
    const request = injections.requests[0];

    beforeEach(() => {
      wrapper = getWrapper(opts);
    });

    it('"Me" is displayed as the name of student', () => {
      expect(wrapper.get('.test-student-name').text()).toBe('Me');
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

    it('has help request submitted date', () => {
      expect(
        wrapper.findAll('[data-content-type=\'request_submitted_date\']')[0].text()
      ).toBe(new ZonedDateTime(request.created_at).formattedDate());
    });

    it('has help request submitted time', () => {
      expect(
        wrapper.findAll('[data-content-type=\'request_submitted_date\']')[1].text()
      ).toBe(new ZonedDateTime(request.created_at).formattedTime());
    });

    it('"Remove" link is visible', () => {
      expect(
        wrapper.get('[data-content-type=\'request_cancel_link\']').classes('u-hidden')
      ).not.toBe(true);
    });
  });
});


describe('StudentRequestForHelp when Instructor response is present', () => {
  const props = {
    helpableItemId: 'direction_line',
  };

  const injections = {
    metaData: {
      activityId: '46224',
      programId: '80',
      sectionId: '53',
      userType: 'Student',
    },
    requests: [
      {
        activity_id: 46224,
        activity_state: 'show',
        created_at: '2021-03-26T01:36:54-04:00',
        helpable_item_id: 'question_01_prompt',
        helpable_item_type: null,
        id: 41,
        instructor_comment: 'Help Request Processed.',
        instructor_name: 'Lolita Stracke',
        processed_at: '2021-03-26T03:06:09-04:00',
        program_id: 80,
        read_by_student: false,
        request_type: 'request_help',
        section_id: 53,
        status: 'submitted',
        student_comment: 'Doubt over Direction Line',
        student_name: 'Brando Kunde',
        user_id: 24,
      },
    ],
  };

  const opts = { injections: injections, props: props };

  describe('I can see common help request information.', () => {
    let wrapper;
    const request = injections.requests[0];

    beforeEach(() => {
      wrapper = getWrapper(opts);
    });

    it('check if wrapper exists', () => {
      expect(wrapper.exists()).toBe(true);
    });

    it('"Me" is displayed as the name of student', () => {
      expect(wrapper.get('.test-student-name').text()).toBe('Me');
    });

    it('has comment of the student', () => {
      expect(wrapper.get('.test-student-comment-text').text()).toBe(request.student_comment);
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

    it('has processed date', () => {
      expect(
        wrapper.findAll('[data-content-type=\'request_responded_date\']')[0].text()
      ).toBe(new ZonedDateTime(request.processed_at).formattedDate());
    });

    it('has processed time', () => {
      expect(
        wrapper.findAll('[data-content-type=\'request_responded_date\']')[1].text()
      ).toBe(new ZonedDateTime(request.processed_at).formattedTime());
    });

    it('"Remove" link is visible', () => {
      expect(wrapper.find('[data-content-type=\'request_cancel_link\']').exists()).toBeFalsy();
    });
  });
});
