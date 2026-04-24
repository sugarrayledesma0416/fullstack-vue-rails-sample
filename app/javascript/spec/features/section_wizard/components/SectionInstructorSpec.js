import { reactive } from 'vue';
import { mount } from '@vue/test-utils';
import SectionInstructor from 'features/section_wizard/components/SectionInstructor';

let wrapper;

VHL = { Music: { V1: {}}};

VHL.Music.V1.Disclosure = class Disclosure {
  constructor() {}
};

let sectionInstructors;

const section = {
  hideOwnerName: false,
  instructor: { id: 23 },
  instructorRoles: ['', 'Co-instructor', 'Assistant'],
  autorosterLinked: false,
  sectionInstructorsWithRoles: function(instructors) {
    return instructors.filter((instructor) => {
      return instructor.role != '';
    });
  },
  descendingByRole: function(instructors) {
    return instructors?.sort(function(a, b) {
      if (a.role > b.role) {
        return -1;
      } else if (a.role < b.role) {
        return 1;
      } else {
        return 0;
      }
    });
  },
};

const config = {
  currentUserRostering: false,
  instAdmin: false,
  mode: 'new_section',
  schoolId: '106',
};

/**
 * This method gets wrapper for SectionInstructor component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(SectionInstructor, {
    global: {
      provide: {
        config,
        datastore: { section },
      },
    },
  });
}

describe('SectionInstructor', () => {
  beforeEach(() => {
    sectionInstructors = reactive(
      [
        { user_id: 1, full_name: 'Lolita Stracke', role: 'Instructor', email: 'lolita@email.com' },
        { user_id: 2, full_name: 'Elise Herzog', role: '', email: '' },
        { user_id: 3, full_name: 'Megane Walter', role: '', email: null },
      ]
    );
    section.sectionInstructors = sectionInstructors;
  });

  describe('onMounted', () => {
    beforeEach(() => {
      sectionInstructors[1].role = 'Assistant';
      sectionInstructors[2].role = 'Co-instructor';
      sectionInstructors[2].allowed_to_edit_content = true;
      wrapper = getWrapper();
    });

    it(
      'displays the Instructor Role modal when the instructor roles link is clicked',
      async () => {
        await wrapper.get('.test-show-instructor-role-modal').trigger('click');
        expect(wrapper.findComponent({ name: 'InstructorRolesModal' }).exists()).toBeTruthy();
      }
    );

    it(
      'displays list of instructor sorted by their roles in descending order"',
      () => {
        const instructorElms = wrapper.findAll('.test-instructor-detail');

        expect(instructorElms[0].find('.test-instructor-role').text()).toBe(
          'Instructor'
        );
        expect(instructorElms[0].find('.test-instructor-fullname').text()).toBe(
          'Lolita Stracke'
        );
        expect(instructorElms[0].find('.test-instructor-email').text()).toBe(
          'lolita@email.com'
        );
        expect(
          instructorElms[0].get('.test-allowed-to-edit-content-checkbox').element.checked
        ).toBeTruthy();


        expect(instructorElms[1].find('.test-instructor-role').text()).toBe(
          'Co-instructor'
        );
        expect(instructorElms[1].find('.test-instructor-fullname').text()).toBe(
          'Megane Walter'
        );
        expect(
          instructorElms[1].get('.test-allowed-to-edit-content-checkbox').element.checked
        ).toBeTruthy();

        expect(instructorElms[2].find('.test-instructor-role').text()).toBe(
          'Assistant'
        );
        expect(instructorElms[2].find('.test-instructor-fullname').text()).toBe(
          'Elise Herzog'
        );
        expect(
          instructorElms[2].get('.test-allowed-to-edit-content-checkbox').element.checked
        ).toBeFalsy();
      }
    );

    it(
      'displays a checkbox for allowing content editing when ' +
      'an instructor is a co-instructor',
      () => {
        const instructorElms = wrapper.findAll('.test-instructor-detail');
        const instructorElm = instructorElms[0];

        expect(
          instructorElm.find('.test-allowed-to-edit-content-checkbox').exists()
        ).toBeTruthy();
      }
    );

    it(
      'displays a disabled checkbox for allowing content editing when ' +
      'an instructor is an assistant',
      () => {
        const instructorElms = wrapper.findAll('.test-instructor-detail');
        const instructorElm = instructorElms[2];

        expect(
          instructorElm.find('.test-allowed-to-edit-content-checkbox').element.disabled
        ).toBeTruthy();
      }
    );

    it(
      'displays the checkbox for allowing content editing when an ' +
      'assistant is changed to a co-instructor',
      async () => {
        const instructorElms = wrapper.findAll('.test-instructor-detail');
        const instructorElm = instructorElms[2];

        const instructorSelectElms = wrapper.findAll('.test-additional-instructor');
        const instructorSelectElm = instructorSelectElms[1];
        const selectElm = instructorSelectElm.get('.test-section-instructor-roles');
        selectElm.element.value = 'Co-instructor';
        await selectElm.trigger('change');

        expect(
          instructorElm.find('.test-allowed-to-edit-content-checkbox').element.disabled
        ).toBeFalsy();
      }
    );
  });

  it(
    'displays the checkbox as checked when a co-instructor is allowed to ' +
    'edit content',
    () => {
      section.sectionInstructors[1].role = 'Co-instructor';
      section.sectionInstructors[1].allowed_to_edit_content = true;

      wrapper = getWrapper();
      const instructorElms = wrapper.findAll('.test-instructor-detail');
      const instructorElm = instructorElms[1];

      expect(
        instructorElm.get('.test-allowed-to-edit-content-checkbox').element.checked
      ).toBeTruthy();
    }
  );

  it(
    'displays the checkbox as unchecked when a co-instructor is not allowed ' +
    'to edit content',
    () => {
      section.sectionInstructors[1].role = 'Co-instructor';
      section.sectionInstructors[1].allowed_to_edit_content = false;

      wrapper = getWrapper();
      const instructorElms = wrapper.findAll('.test-instructor-detail');
      const instructorElm = instructorElms[1];

      expect(
        instructorElm.get('.test-allowed-to-edit-content-checkbox').element.checked
      ).toBeFalsy();
    }
  );

  describe('when "autorosteringLinked" is true', () => {
    it('does not display "Add/Edit Additional Instructors" section', async () => {
      section.autorosteringLinked = true;
      wrapper = getWrapper();
      expect(wrapper.findComponent({ name: 'AdditionalInstructor' }).exists()).toBeFalsy();
    });
  });


  describe('when "autorosteringLinked" is false', () => {
    it('displays "Add/Edit Additional Instructors" section', async () => {
      section.autorosteringLinked = false;
      wrapper = getWrapper();
      expect(wrapper.findComponent({ name: 'AdditionalInstructor' }).exists()).toBeTruthy();
    });
  });
});
