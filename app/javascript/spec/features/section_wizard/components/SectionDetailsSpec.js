import { mount } from '@vue/test-utils';
import SectionDetails from 'features/section_wizard/components/SectionDetails';
import { reactive } from 'vue';

VHL = { Music: { V1: {}}};
VHL.Music.V1.Disclosure = class Disclosure {
  constructor() {}
};

let wrapper;

const section = {
  assignmentAvailabilityMessage: 'All upcoming assignments available to students.',
  allowEnrollmentLock: true,
  assignmentCopySectionId: 'None',
  assignmentsPresent: false,
  copySectionHasExternalAssignments: false,
  course: { id: 39, name: 'sddf', program_id: 79, owner_id: 23 },
  daysToShowAssignmentDueDate: null,
  canCopyAssignments: true,
  courseSections: [
    {
      assignmentPastDueCount: 4,
      id: 54,
      name: 'test 1234',
    },
  ],
  availableOptions: {
    'Frequently Used': [
      { text: 'Always', value: null, group: 'Frequently Used' },
      { text: '1 Week', value: 7, group: 'Frequently Used' },
    ],
    'Other': [
      { text: '1 day', value: 1, group: 'Other' },
      { text: '2 days', value: 2, group: 'Other' },
      { text: '3 days', value: 3, group: 'Other' },
    ],
  },
  name: null,
  oneRosterLinked: false,
  openToStudents: true,
};

/**
 * This method gets wrapper for SectionDetails component
 * @param {Object} section - section data required for the component.
 * @return {Wrapper}
 */
function getWrapper(section) {
  return mount(SectionDetails, {
    global: {
      provide: {
        datastore: reactive({ section: section }),
      },
    },
  });
}

describe('SectionDetails', () => {
  describe('when canCopyAssignments is "true"', () => {
    beforeEach(() => {
      wrapper = getWrapper(section);
    });

    it('displays "Copy assignments & due dates from another section"', () => {
      expect(
        wrapper.get('.test-copy-assignment').text()
      ).toBe('Copy assignments & due dates from another section');
    });

    it('displays 2 options for previous section', () => {
      expect(wrapper.get('.test-previous-section').findAll('option').length).toBe(2);
    });

    describe('when copySectionHasExternalAssignments is "false"', () => {
      it(
        'displays an informacion modal when the individual assignment link is clicked',
        async () => {
          await wrapper.get('.test-show-individual-assignment-information-modal').trigger('click');
          expect(wrapper.get('.test-show-individual-assignment-information-text').text())
            .toBe('When copying individually assigned activities to a new section, ' +
                  'all students in the section will receive these assignments.  ' +
                  'Copying Group Chat activities will also copy over their settings.');
        }
      );
    });

    describe('when copySectionHasExternalAssignments is "true"', () => {
      beforeEach(() => {
        section.copySectionHasExternalAssignments = true;
        wrapper = getWrapper(section);
      });

      it(
        'does not display the individual assignment information link', () => {
          expect(wrapper.find('.test-show-individual-assignment-information-modal').exists())
            .toBeFalsy();
        });
    });
  });

  describe('when canCopyAssignments is "false"', () => {
    beforeEach(() => {
      section.canCopyAssignments = false;
      wrapper = getWrapper(section);
    });

    it('does not displays "Copy assignments & due dates from another section"', () => {
      expect(wrapper.find('.test-copy-assignment').exists()).toBeFalsy();
    });

    it('does not displays 2 options for previous section', () => {
      expect(wrapper.find('.test-previous-section').exists()).toBeFalsy();
    });
  });

  describe('when allowEnrollmentLock is "true"', () => {
    beforeEach(() => {
      wrapper = getWrapper(section);
    });

    it('displays "Allow new students to enroll in this course section"', () => {
      expect(
        wrapper.get('.test-allow-students').text()
      ).toBe('Allow new students to enroll in this course section');
    });

    it('displays the checkbox to allow new students to enroll', () => {
      expect(wrapper.find('.test-section-open-to-students').exists()).toBeTruthy();
    });
  });

  describe('when allowEnrollmentLock is "false"', () => {
    beforeEach(() => {
      section.allowEnrollmentLock = false;
      wrapper = getWrapper(section);
    });

    it('does not displays "Allow new students to enroll in this course section"', () => {
      expect(wrapper.find('.test-allow-students').exists()).toBeFalsy();
    });

    it('displays the checkbox to allow new students to enroll', () => {
      expect(wrapper.find('.test-section-open-to-students').exists()).toBeFalsy();
    });
  });

  describe('AssignmentAvailability', () => {
    beforeEach(() => {
      wrapper = getWrapper(section);
    });

    it('displays default assignment availability message', () => {
      expect(
        wrapper.get('.test-assignment-available-msg').text()
      ).toBe('All upcoming assignments available to students.');
    });
  });

  describe('when AssignmentAvailability is changed', () => {
    beforeEach(async () => {
      wrapper = getWrapper(section);
      await wrapper.get('.test-assignment-availability').trigger('click');
      const selectTag = wrapper.get('.test-due-days-left-for-assignment');
      selectTag.element.value = '7';
      await selectTag.trigger('change');
    });

    it('displays the changed value of "1 week"', () => {
      expect(
        wrapper.get('.test-due-days-left-for-assignment').get('option:checked').text()
      ).toBe('1 Week');
    });
  });
});
