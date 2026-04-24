import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import ClassDays from 'features/section_wizard/components/ClassDays';

let wrapper;

const section = {
  possibleClassDays: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
  classDays: {},
};

/**
 * This method gets wrapper for ClassDays component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(ClassDays, {
    global: {
      provide: {
        datastore: reactive({ section }),
      },
    },
  });
}

describe('ClassDays', () => {
  describe('when ClassDays is mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays all the days of the week', () => {
      section.possibleClassDays.forEach((day) => {
        expect(wrapper.get(`.test-week-days-${day}`).text()).toBe(day);
      });
    });
  });

  describe('when a set of days(or day) are selected', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await wrapper.get('.test-section-days-Mon').trigger('click');
      await wrapper.get('.test-section-days-Wed').trigger('click');
    });

    it('displays "Monday" as selected', () => {
      expect(wrapper.get('.test-section-days-Mon').element.checked).toBeTruthy();
    });

    it('displays "Wednesday" as selected', () => {
      expect(wrapper.get('.test-section-days-Wed').element.checked).toBeTruthy();
    });

    it('does not display "Tuesday" as selected', () => {
      expect(wrapper.get('.test-section-days-Tue').element.checked).toBeFalsy();
    });
  });
});
