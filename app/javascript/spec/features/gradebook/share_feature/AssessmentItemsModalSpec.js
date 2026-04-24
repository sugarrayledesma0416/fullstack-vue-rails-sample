import { mount } from '@vue/test-utils';
import AssessmentItemsModal from 'features/gradebook/share_feature/AssessmentItemsModal';
import fetchMock from 'fetch-mock';

const props = {
  assessmentItemModalConfig: {
    isModalOpen: false,
    itemGuids: ['1234', '2345'],
    standardLabel: 'ELD-LA.6-8.Inform.Interpretive.2',
  },
  reviewPath: 'review/path',
  standardDetails: {
    'id': 12940,
    'label': 'ELD-LA.6-8.Inform.Interpretive.2',
    'description': 'Analyzing observations and descriptions in textual evidence for key attributes, qualities, characteristics, activities, and behaviors',
    'standard_guid': '4937D2ED-DF84-4CA3-B989-CEF26784CA49',
  },
};

function getWrapper() {
  return mount(
    AssessmentItemsModal,
    {
      global: { stubs: { QuestionItem: true } },
      props: props,
    });
}

describe(
  'AssessmentItemsModalSpec',
  () => {
    let wrapper;
    beforeEach(async () => {
      fetchMock.mock(
        '/review/path?assessment_item_guid=1234',
        '<div>modal html item 1</div>',
      );
      fetchMock.mock(
        '/review/path?assessment_item_guid=2345',
        '<div>modal html item 2</div>',
      );
      wrapper = getWrapper();
    });

    afterEach(() => {
      wrapper.vm.props.assessmentItemModalConfig.isModalOpen = false;
      fetchMock.restore();
    });

    it('displays "ModalComponent" component', () => {
      expect(wrapper.findComponent({ name: 'ModalComponent' }).exists()).toBeTruthy();
    });


    it('increments selected Item Number when next button is clicked', async () => {
      //this opens the modal
      wrapper.vm.props.assessmentItemModalConfig.isModalOpen = true;
      await wrapper.vm.$nextTick();
      await wrapper.find('.test-next-button').trigger('click');
      expect(wrapper.vm.selectedItemNumberRef).toBe(1);
    });

    it('decrements selected Item Number when previous button is clicked', async () => {
      //this opens the modal in the second item per say so the previous button is enabled
      wrapper.vm.props.assessmentItemModalConfig.isModalOpen = true;
      wrapper.vm.selectedItemNumberRef = 1;
      await wrapper.vm.$nextTick();

      await wrapper.find('.test-previous-button').trigger('click');
      expect(wrapper.vm.selectedItemNumberRef).toBe(0);
    });
  }
);
