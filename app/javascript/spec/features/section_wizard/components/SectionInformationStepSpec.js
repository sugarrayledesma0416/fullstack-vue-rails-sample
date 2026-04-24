import { shallowMount } from '@vue/test-utils';
import { reactive } from 'vue';
import SectionInformationStep from 'features/section_wizard/components/SectionInformationStep';
import FlashMessageState from 'shared/flash_message_state';
import { flattenDiagnosticMessageText } from 'typescript';


let wrapper;

const section = {
  name: null,
  course: {
    id: 39,
    name: 'tesCourse',
    owner_id: 23,
    program_id: 79,
  },
  showPreview: true,
};


const props = {
  loadingImg: '/assets/loading_32.gif',
  remainingTimeZones: [
    ['(GMT-11:00) American Samoa', 'American Samoa'],
    ['(GMT-08:00) Tijuana', 'Tijuana'],
  ],
  timeZones: [
    ['(GMT-05:00) Eastern Time (US & Canada)', 'Eastern Time (US & Canada)'],
    ['(GMT-06:00) Central Time (US & Canada)', 'Central Time (US & Canada)'],
    ['(GMT-07:00) Arizona', 'Arizona'],
  ],
};

const config = {
  currentUserRostering: false,
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
  return shallowMount(SectionInformationStep, {
    global: {
      provide: {
        config,
        datastore: reactive({ section }),
        flashMessageState: new FlashMessageState(),
      },
    },
    props,
  });
}

describe('SectionInformationStep', () => {
  describe('when component is mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper(config, section);
    });

    it('displays the SectionNameAndInfo component', () => {
      expect(
        wrapper.findComponent({ name: 'SectionNameAndInfo' }).exists()
      ).toBeTruthy();
    });

    it('displays the SectionDetails component', () => {
      expect(
        wrapper.findComponent({ name: 'SectionDetails' }).exists()
      ).toBeTruthy();
    });

    it('displays the ClassDays component', () => {
      expect(
        wrapper.findComponent({ name: 'ClassDays' }).exists()
      ).toBeTruthy();
    });

    it('displays the Schedule component', () => {
      expect(
        wrapper.findComponent({ name: 'Schedule' }).exists()
      ).toBeTruthy();
    });

    it('displays the SaveAndCancel component', () => {
      expect(
        wrapper.findComponent({ name: 'SaveAndCancel' }).exists()
      ).toBeTruthy();
    });
  });

  describe('when config.instAdmin is "false"', () => {
    beforeEach(() => {
      wrapper = getWrapper(config, section);
    });

    it('displays the SectionInstructor component', () => {
      expect(
        wrapper.findComponent({ name: 'SectionInstructor' }).exists()
      ).toBeTruthy();
    });
  });

  describe('when config.instAdmin is "true"', () => {
    beforeEach(() => {
      config.instAdmin = true;
      wrapper = getWrapper(config, section);
    });

    it('does not displays the SectionInstructor component', () => {
      expect(
        wrapper.findComponent({ name: 'SectionInstructor' }).exists()
      ).toBeFalsy();
    });
  });

  describe('when datastore.section.showPreview is true', () => {
    beforeEach(() => {
      config.instAdmin = false;
      wrapper = getWrapper(config, section);
    });

    it('displays StudentPreview component', () => {
      expect(
        wrapper.findComponent({ name: 'Expander' }).props().expanded
      ).toBeTruthy();
    });
  });

  describe('when datastore.section.showPreview is false', () => {
    beforeEach(() => {
      section.showPreview = false;
      config.instAdmin = false;
      wrapper = getWrapper(config, section);
    });

    it('does not expand the preview expander component', () => {
      expect(
        wrapper.findComponent({ name: 'Expander' }).props().expanded
      ).toBeFalsy();
    });
  });
});
