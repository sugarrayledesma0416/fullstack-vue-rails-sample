import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
/* eslint-disable-next-line max-len */
import StandardsDetails from 'features/gradebook/standards/student_detail_report/StandardsDetails';

import fetchMock from 'fetch-mock';

const props = {
  reviewPath: 'review/path',
  standardDetails: {
    id: 13029,
    label: 'ELD-LA.6-8.Inform.Interpretive',
    description: 'Multilingual learners will interpret informational texts in language arts by',
    standard_guid: '',
  },
  standardsAssigningUrl: 'url/to/standards/assigning',
  summary: {
    '4D22CCBC-3D04-43FB-BE8B-66E6479CB264': {
      954139: {
        label: 'End-of-Unit',
        percent_correct: 10,
        items_count: 10,
        assessment_item_guids:
        [
          'a8a4ca30-d3b1-49ff-8e63-3fc441c4ab72',
          '47bff553-025d-4366-ba01-73aaa0946130',
          'bdeb0642-cac7-42cb-b29d-588e56f86b74',
          '6a8df5d5-e70a-493c-8b28-8e6027e5de8f',
          '00023821-7462-4cfc-83cd-ef3b0468284e',
          '79ad4fff-2dba-45ce-a396-e83d599d2c82',
          'e2accde6-9e4b-44da-85b6-0b6ef5237a3e',
          'e2d9c7d1-c27c-47c2-a1bf-b953f9923c62',
          '776b8619-829b-4ec9-a77e-b13cb51f3dbb',
          '26d0d34c-48f4-4ab1-9eb7-782b02ccc52b',
        ],
        total_percent_correct: 100,
      },
    },
  },
  tooltipInfo: {
    standardsAssessed: {
      text: 'The name of the standards that were assessed as part of this unit.',
      position: 'top',
    },
    percentage: {
      text: 'Percent score achieved by student on the individual standard. This is calculated by dividing the points achieved by the total points possible.',
      position: 'top',
    },
    items: {
      text: 'Total number of questions presented for the individual standard.',
      position: 'top',
    },
    score: {
      text: 'Score achieved by student on the individual standard presented in a specific assessment.',
      position: 'top',
    },
  },
};

function getWrapper() {
  return shallowMount(
    StandardsDetails,
    {
      global: { stubs: { AssessmentItemsModal: false } },
      props: props,
    });
}

describe(
  'StandardsDetailsSpec',
  () => {
    let wrapper;
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('Check if standard details exist', () => {
      expect(wrapper.vm.standardDetails).not.toBeNull();
    });

    it('Check if summary object exist', () => {
      expect(wrapper.vm.summary).not.toBeNull();
    });

    it('Check if tooltip info object exist', () => {
      expect(wrapper.vm.tooltipInfo).not.toBeNull();
    });

    it('Shows standards label', ()=> {
      expect(wrapper.findAll('.test-standard-details-label').length).toBe(1);
    });

    it('Shows standards description', ()=> {
      expect(wrapper.findAll('.test-standard-details-description').length).toBe(1);
    });

    it('Shows a link to find matching content', ()=> {
      expect(wrapper.find('.test-search-matching-content').exists()).toBeTruthy();
    });

    describe('when clicking on an assessment percent', () => {
      it('Shows the assessment items review modal', async () => {
        fetchMock.mock(
          '/review/path?assessment_item_guid=a8a4ca30-d3b1-49ff-8e63-3fc441c4ab72',
          '<div> show html </div>'
        );
        wrapper.vm.props.standardDetails.standard_guid = '4D22CCBC-3D04-43FB-BE8B-66E6479CB264';
        await nextTick();
        await wrapper.find('.test-assessment-percent-End-of-Unit').trigger('click');
        expect(wrapper.find('.test-assessment-items-review-modal').isVisible()).toBeTruthy();
      });
    });
  }
);
