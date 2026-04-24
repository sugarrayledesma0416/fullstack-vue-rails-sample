import { shallowMount } from '@vue/test-utils';
import NewSectionWizardApp from 'features/section_wizard/NewSectionWizardApp';
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
 * This method gets wrapper for NewSectionWizardApp component
 * @return {Wrapper}
 */
function getWrapper() {
  return shallowMount(NewSectionWizardApp, { props });
}

describe('NewSectionWizardApp', () => {
  describe('when component is mounted', () => {
    beforeEach(() => {
      const url = 'http://localhost/';
      spyOn(ajaxUtils, 'getWithAcceptHeaders').and.callThrough();
      fetchMock.mock(url, { status: 200, body: sectionResponse });

      wrapper = getWrapper();
    });

    it('displays component named "SectionInformationStep"', async () => {
      await fetchMock.flush(true);
      await wrapper.vm.$nextTick();
      expect(wrapper.findComponent({ name: 'SectionInformationStep' }).exists()).toBeTruthy();
    });
  });
});
