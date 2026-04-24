import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import AssignmentCopyAlertBox from 'features/section_wizard/components/AssignmentCopyAlertBox';

const sectionIdWithPastDueCount = 1;
const sectionIdWithoutPastDueCount = 1;

const sectionData = {
  assignmentCopySectionId: null,
  previousSections: [
    { id: sectionIdWithPastDueCount, assignmentPastDueCount: 7 },
    { id: sectionIdWithoutPastDueCount, assignmentPastDueCount: 0 },
  ],
};

/**
 * This method gets wrapper for AssignmentCopyAlertBox component
 * @param {Object} datastore - Data provided for AssignmentCopyAlertBox component
 * @return {Wrapper}
 */
function getWrapper(datastore) {
  return mount(AssignmentCopyAlertBox, {
    global: {
      provide: { datastore },
    },
  });
}

let wrapper;
let datastore;

describe('AssignmentCopyAlertBox', () => {
  describe('when AssignmentCopyAlertBox is mounted', () => {
    beforeEach(() => {
      datastore = reactive({ section: sectionData });
      wrapper = getWrapper(datastore);
    });

    it('does not display flash message', () => {
      expect(wrapper.find('.test-flash-warning').exists()).toBeFalsy();
    });
  });

  describe('when "assignmentCopySectionId" in provided datastore is changed' +
    ' to a previous section with passed due dates', () => {
    beforeEach(async () => {
      datastore = reactive({ section: sectionData });
      wrapper = getWrapper(datastore);
      // update property in injected data to trigger watcher on assignmentCopySectionId.
      datastore.section.assignmentCopySectionId = sectionIdWithPastDueCount;
      await wrapper.vm.$nextTick();
    });

    afterEach(() => {
      // Reset assignmentCopySectionId in datastore so that
      // watcher would keep detecting the change in it.
      datastore.section.assignmentCopySectionId = null;
    });

    it('displays flash warning', () => {
      expect(wrapper.find('.test-flash-warning').exists()).toBeTruthy();
    });

    it('displays past due dates message in flash warning', () => {
      const dueDateMsg = '7 assignments have due dates already in the past.';
      expect(wrapper.find('.test-due-dates-message').text()).toBe(dueDateMsg);
    });

    it('closes the flash warning when close link is clicked', async () => {
      await wrapper.get('.test-flash-banner-close-link').trigger('click');
      expect(wrapper.find('.test-flash-warning').exists()).toBeFalsy();
    });
  });

  describe('when "assignmentCopySectionId" in provided datastore is changed' +
    ' to a previous section without passed due dates', () => {
    beforeEach(async () => {
      datastore = reactive({ section: sectionData });
      wrapper = getWrapper(datastore);
      // update property in injected data to trigger watcher on assignmentCopySectionId.
      datastore.section.assignmentCopySectionId = sectionIdWithoutPastDueCount;
      await wrapper.vm.$nextTick();
    });

    it('displays flash warning', () => {
      expect(wrapper.find('.test-flash-warning').exists()).toBeTruthy();
    });

    it('does not display past due dates message', () => {
      expect(wrapper.find('.test-due-dates-message').exists()).toBeFalsy();
    });
  });
});
