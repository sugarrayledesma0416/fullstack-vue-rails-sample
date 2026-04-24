import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import SectionNameAndInfo from 'features/section_wizard/components/SectionNameAndInfo';

let wrapper;

const section = {
  name: null,
  oneRosterLinked: false,
  additionalInfo: '',
  isValidatorEnabled: false,
  hasError: {
    value: false,
    msg: '',
  },
};


/**
 * This method gets wrapper for SectionNameAndInfo component
 * @param {Object} section - section model required for the component.
 * @return {Wrapper}
 */
function getWrapper(section) {
  return mount(SectionNameAndInfo, {
    global: {
      provide: {
        datastore: reactive({ section }),
      },
    },
  });
}

describe('SectionNameAndInfo', () => {
  describe('when SectionNameAndInfo is mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper(section);
    });

    it('displays label of "New Section Name"', () => {
      expect(wrapper.get('.test-section-name-label').text()).toBe('New Section Name');
    });

    it('displays section name input field as blank', () => {
      expect(wrapper.get('.test-section-name').text()).toBe('');
    });

    it('displays label of "Additional section information (optional)"', () => {
      expect(
        wrapper.get('.test-section-additional-info').text()
      ).toBe('Additional section information (optional)');
    });

    it('displays additional info input field as blank', () => {
      expect(wrapper.get('.test-section-additionalInfo').text()).toBe('');
    });
  });

  describe('when hasError.value is "true"', () => {
    beforeEach(() => {
      section.hasError.value = true;
      section.hasError.msg = 'Section name is required.';
      wrapper = getWrapper(section);
    });

    it('displays a invalid section div with error msg', () => {
      expect(wrapper.get('.test-invalid-section').text()).toBe('Section name is required.');
    });
  });
});
