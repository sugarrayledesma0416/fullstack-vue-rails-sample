import { shallowMount } from '@vue/test-utils';
/* eslint-disable-next-line max-len */
import StandardsListByRange from 'features/gradebook/standards/student_detail_report/StandardsListByRange';

const props = {
  standardListByRange: {
    '4D22CCBC-3D04-43FB-BE8B-66E6479CB264': {
      'label': 'ELD-LA.6-8.Inform.Interpretive',
      'percent_correct': 10,
      'items_count': 10,
      'total_percent_correct': 100,
    },
    '4937D2ED-DF84-4CA3-B989-CEF26784CA49': {
      'label': 'ELD-LA.6-8.Inform.Interpretive.2',
      'percent_correct': 0,
      'items_count': 1,
      'total_percent_correct': 0,
    },
    'F32E384C-9E49-4DF6-8700-D61F70647608': {
      'label': 'ELD-LA.6-8.Inform.Interpretive.3',
      'percent_correct': 50,
      'items_count': 2,
      'total_percent_correct': 100,
    },
    'F585E0B2-A18F-401A-B157-47B7B558C0B5': {
      'label': 'ELD-LA.6-8.Narrate.Interpretive',
      'percent_correct': 25,
      'items_count': 4,
      'total_percent_correct': 100,
    },
    '4C59E1C5-AED2-449C-9E60-F96727FB0349': {
      'label': 'ELD-LA.6-8.Narrate.Interpretive.2',
      'percent_correct': 50,
      'items_count': 2,
      'total_percent_correct': 100,
    },
    'B513CB4B-C78E-4B9B-9517-A4C90D9C6C00': {
      'label': 'ELD-LA.6-8.Narrate.Interpretive.3',
      'percent_correct': 50,
      'items_count': 2,
      'total_percent_correct': 100,
    },
    'C8148FA9-B777-40DD-982D-8F08BCD60EED': {
      'label': 'ELD-SI.4-12.Narrate.1',
      'percent_correct': 55.55555555555556,
      'items_count': 9,
      'total_percent_correct': 500,
    },
    '903D47AF-26F6-46C6-913B-4807ABCDCDEB': {
      'label': 'ELD-LA.6-8.Narrate.Expressive',
      'percent_correct': 50,
      'items_count': 1,
      'total_percent_correct': 50,
    },
    'C1B35965-B7D7-4102-B2F9-54D08C2D1354': {
      'label': 'ELD-LA.6-8.Narrate.Interpretive.1',
      'percent_correct': 100,
      'items_count': 1,
      'total_percent_correct': 100,
    },
  },
  selectedStandardGuid: '4D22CCBC-3D04-43FB-BE8B-66E6479CB264',
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
    StandardsListByRange,
    {
      global: { stubs: {
        'vhl-column-unsorted-icon': true,
        'vhl-column-descending-icon': true,
      }},
      props: props,
    });
}

describe(
  'StandardsListByRangeSpec',
  () => {
    let wrapper;
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('Shows the standards list by range', ()=> {
      expect(wrapper.findAll('.test-standard-list-item').length).toBe(9);
    });

    it('Check if tooltip info object exist', () => {
      expect(wrapper.vm.tooltipInfo).not.toBeNull();
    });

    describe(
      'when clicking on a standard category',
      () => {
        let wrapper;
        beforeEach(async () => {
          wrapper = getWrapper();
        });

        it('emits "getStandardDetails" event', async () => {
          const itemElms = await wrapper.findAll('.test-standard-list-item');
          itemElms[0].trigger('click');
          expect(wrapper.emitted().getStandardDetails).toBeTruthy();
        });
      }
    );

    describe('setSelectedStandardDetails function', () => {
      it('emits getStandardDetails with correct payload', async () => {
        const standardData =
          props.standardListByRange['4D22CCBC-3D04-43FB-BE8B-66E6479CB264'];

        wrapper.vm.setSelectedStandardDetails(standardData, props.selectedStandardGuid);
        expect(wrapper.emitted().getStandardDetails[0]).toEqual([{
          label: 'ELD-LA.6-8.Inform.Interpretive',
          standard_guid: '4D22CCBC-3D04-43FB-BE8B-66E6479CB264',
        }]);
      });
    });
  }
);
