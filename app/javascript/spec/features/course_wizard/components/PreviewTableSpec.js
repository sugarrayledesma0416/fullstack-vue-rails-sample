import { reactive } from 'vue';
import { mount } from '@vue/test-utils';
import PreviewTable from 'features/course_wizard/components/PreviewTable';
import Course from 'features/course_wizard/models/course';
VHL.Music.Tooltip = jest.fn();

const config = {
  currentUser: { last_name: 'Stracke' },
  instAdmin: false,
  programId: '79',
  vol: true,
};

const courseDataStore = {
  store: reactive({
    course: new Course,
    courseOptions: {
      settings: [
        {
          name: 'Express-1',
          sections: [
            {
              additionalInfo: null,
              id: 121,
              name: 'Express-01',
              instructorLastNames: ['Stracke, Lolita'],
              sectionInstructors: [
                {
                  firstName: 'Lolita',
                  fullName: 'Lolita Stracke',
                  lastName: 'Stracke',
                  role: 'Instructor',
                },
              ],
            },
          ],
        },
        {
          name: 'Express-2323222',
          sections: [
            {
              additionalInfo: null,
              id: 122,
              name: 'Express-22222222',
              instructorLastNames: ['Stracke, Lolita'],
              sectionInstructors: [
                {
                  firstName: 'Lolita',
                  fullName: 'Lolita Stracke',
                  lastName: 'Stracke',
                  role: 'Instructor',
                },
              ],
            },
          ],
        },
      ],
    },
  }),
};

let wrapper;

const getWrapper = () => {
  return mount(PreviewTable, {
    global: { provide: { courseDataStore, config }},
    props: { courseType: 'express' },
  });
};

/*
  Grabs reference(s) to open tooltip(s).
  Returns an Array (NOT a wrapper, b/c the tooltips
  are mounted directly inside the document body).
*/
const openTooltips = (selector) => {
  const tippyRoot = 'body > [data-tippy-root]';
  const wholeSelector = `${tippyRoot} ${selector}`;
  const nodes = document.querySelectorAll(wholeSelector);
  if (nodes.length > 0) {
    return nodes;
  } else {
    throw Error('No open tooltips found.');
  }
};

describe('Preview Table', () => {
  describe('onMounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays "Instructor" as heading of first column', () => {
      expect(wrapper.get('.test-instructor-heading').text()).toBe('Instructor');
    });

    it('displays "Course" as heading of second column', () => {
      expect(wrapper.get('.test-course-heading').text()).toBe('Course');
    });

    it('displays "Course" as heading of second column', () => {
      expect(wrapper.get('.test-section-heading').text()).toBe('Section');
    });

    it('displays the current user last name', () => {
      expect(wrapper.get('.test-current-user').text()).toBe('Stracke');
    });
  });
});
