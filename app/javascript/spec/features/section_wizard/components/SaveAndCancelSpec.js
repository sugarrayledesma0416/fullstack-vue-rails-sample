import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import SaveAndCancel from 'features/section_wizard/components/SaveAndCancel';
import FlashMessageState from 'shared/flash_message_state';

let wrapper;

const section = {
  save: jest.fn(),
  update: jest.fn(),
  name: null,
  course: {
    id: 39,
    name: 'tesCourse',
    owner_id: 23,
    program_id: 79,
  },
  saving: false,
  hasError: {
    value: false,
    msg: '',
  },
};

const config = {
  instAdmin: false,
  mode: 'new_section',
  schoolId: '106',
};

/**
 * This method gets wrapper for SaveAndCancel component.
 * @param {Object} config - configuration required throughout the section.
 * @param {Object} section - section model required for the component.
 * @return {Wrapper}
 */
function getWrapper(config, section) {
  return mount(SaveAndCancel, {
    global: {
      provide: {
        config,
        datastore: reactive({ section }),
        flashMessageState: new FlashMessageState(),
      },
    },
    props: { loadingImg: '/assets/loading_32.gif' },
  });
}

describe('SaveAndCancel with mode as "new_section"', () => {
  describe('when hasError.value is false', () => {
    beforeEach(() => {
      section.name = 'testSection';
      wrapper = getWrapper(config, section);
    });

    it('displays "Submit" button in enabled state', () => {
      expect(wrapper.get('.test-submit-btn').element).not.toBeDisabled();
    });
  });

  describe('instAdmin is false', () => {
    beforeEach(() => {
      wrapper = getWrapper(config, section);
    });

    it('displays "Cancel" button which redirects to "instructor dashboard" url', () => {
      expect(
        wrapper.get('.test-cancel-button').element.href
      ).toContain('/instructor/dashboard/79');
    });
  });

  describe('instAdmin is true', () => {
    beforeEach(() => {
      config.instAdmin = true;
      wrapper = getWrapper(config, section);
    });

    it('displays "Cancel" button which redirects to "institution_admin" url', () => {
      expect(
        wrapper.get('.test-cancel-button').element.href
      ).toContain('/institution_admin/templates/79?school_id=106');
    });
  });

  describe('when hasError.value is true', () => {
    beforeEach(() => {
      section.hasError.value = true;
      section.hasError.msg = 'Section name is required.';
      wrapper = getWrapper(config, section);
    });

    it('displays "Submit" button but in disabled state', () => {
      expect(wrapper.get('.test-submit-btn').element).toBeDisabled();
    });
  });
});
