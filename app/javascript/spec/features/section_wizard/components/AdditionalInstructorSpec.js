import { reactive } from 'vue';
import { mount } from '@vue/test-utils';
import AdditionalInstructor from 'features/section_wizard/components/AdditionalInstructor';
import { Section } from 'features/section_wizard/models/section';

VHL = { Music: { V1: {}}};

VHL.Music.V1.Disclosure = class Disclosure {
  constructor() {}
};

let wrapper;

const section = new Section();
section.hideOwnerName = false;
section.instructor = { id: 1 };
section.instructorRoles = ['', 'Co-instructor', 'Assistant'];

function setDefaultRoles() {
  section.sectionInstructors.forEach((instructor) => {
    if (instructor.id !== 1) {
      instructor.role = '';
    }
  });
}

/**
 * This method gets wrapper for AdditionalInstructor component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(AdditionalInstructor, {
    global: {
      provide: {
        datastore: { section },
      },
    },
  });
}

describe('AdditionalInstructor', () => {
  beforeEach(
    () => {
      section.sectionInstructors = reactive(
        [
          { user_id: 1, full_name: 'Lolita Stracke', role: 'Instructor' },
          { user_id: 2, full_name: 'Elise Herzog', email: null, role: '' },
          { user_id: 3, full_name: 'Megane Walter', email: 'megane@gmail.com', role: '' },
        ]
      );
    }
  );

  describe('onMounted', () => {
    beforeEach(() => {
      section.sectionInstructors[1].role = 'Co-instructor';
      section.sectionInstructors[2].role = 'Assistant';
      wrapper = getWrapper();
    });

    it(
      'displays list of Additional Instructors',
      () => {
        const instructorElms = wrapper.findAll('.test-additional-instructor');
        instructorElms.forEach(
          (instructorElm, index) => {
            const instructorFullName = section.sectionInstructors[index + 1].full_name;
            const instructorEmail =
              section.sectionInstructors[index + 1].email ? ` (${section.sectionInstructors[index + 1].email})` : '';
            expect(
              instructorElm.find('.test-additional-instructor-name').text()
            ).toBe(`${instructorFullName}${instructorEmail}`);

            expect(
              instructorElm.find('.test-section-instructor-roles').exists()
            ).toBeTruthy();
          }
        );
      }
    );
  });

  describe('when "Co-instructor" and "Assistant" are not present', () => {
    let hideOwnerElm;

    beforeEach(() => {
      setDefaultRoles();
      wrapper = getWrapper();
      hideOwnerElm = wrapper.get('.test-hide-owner-name');
    });

    it('enables hide-owner-name checkbox', () => {
      expect(hideOwnerElm.element).toBeDisabled();
    });

    it('sets the title of the hide-owner-name checkbox', () => {
      expect(hideOwnerElm.attributes()['title']).toBe(
        'If no other instructors are selected, your name must be shown to students.'
      );
    });
  });

  describe('when at least one "Co-instructor" or "Assistant" is present', () => {
    let hideOwnerElm;

    beforeEach(() => {
      section.sectionInstructors[1].role = 'Assistant';
      wrapper = getWrapper();
      hideOwnerElm = wrapper.get('.test-hide-owner-name');
    });

    it('enables hide-owner-name checkbox', () => {
      expect(hideOwnerElm.element).toBeEnabled();
    });

    it('sets the title of hide-owner-name checkbox to an empty string', () => {
      expect(hideOwnerElm.attributes()['title']).toBe('');
    });
  });
});
