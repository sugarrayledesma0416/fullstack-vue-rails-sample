import { shallowMount } from '@vue/test-utils';
import ShowMappedStandardsApp from 'features/activities/show_header_content/ShowMappedStandardsApp.vue';

const props = {
  unitId: '2965',
  activityId: '954135',
  instructorStandardsAssigningPath: 'dummy/path',
  mappedStandards: '[]',
};

function getWrapper() {
  return shallowMount(
    ShowMappedStandardsApp,
    {
      props: props,
    });
};

describe('ShowMappedStandardsApp',
  () => {
    let wrapper;

    beforeEach(
      () => {
        wrapper = getWrapper();
      }
    );

    it('displays standard button', () => {
      expect(wrapper.find('.test-show-standards-modal-button').exists()).toBeTruthy();
    });

    it('Show StandardsListModal component', () => {
      wrapper.find('.test-show-standards-modal-button').trigger('click');
      expect(wrapper.vm.standardModal).toBeTruthy();
    });
  });
