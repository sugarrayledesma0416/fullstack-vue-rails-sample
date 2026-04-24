import { shallowMount } from '@vue/test-utils';
import EditSectionWizardApp from 'features/section_wizard/EditSectionWizardApp';
import * as ajaxUtils from 'shared/ajax_utils';
import fetchMock from 'fetch-mock';

let wrapper;
const sectionResponse = {
  additional_info: '',
  course: {},
  name: '',
  time_zone: 'Eastern Time (US & Canada)',
};

const props = {
  currentUserRostering: false,
  loadingImg: '/assets/loading_32.gif',
  remainingTimeZones: [
    ['(GMT-11:00) American Samoa', 'American Samoa'],
    ['(GMT-08:00) Tijuana', 'Tijuana'],
  ],
  timeZones: [
    ['(GMT-05:00) Eastern Time (US & Canada)', 'Eastern Time (US & Canada)'],
    ['(GMT-07:00) Arizona', 'Arizona'],
  ],
};

/**
 * This method gets wrapper for EditSectionWizardApp component
 * @return {Wrapper}
 */
function getWrapper() {
  return shallowMount(EditSectionWizardApp, { props });
}

describe('EditSectionWizardApp', () => {
  describe('when component is mounted', () => {
    beforeEach(async () => {
      const url = 'http://localhost/.json';
      spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
      fetchMock.mock(url, { status: 200, body: sectionResponse }, { overwriteRoutes: false });

      wrapper = getWrapper();
      await fetchMock.flush(true);
      await wrapper.vm.$nextTick();
    });

    it('displays Edit Section form', () => {
      expect(wrapper.find('.test-edit-section-form').exists()).toBeTruthy();
    });

    it('displays component named "SectionInformationStep"', () => {
      expect(wrapper.findComponent({ name: 'SectionInformationStep' }).exists()).toBeTruthy();
    });
  });
});
