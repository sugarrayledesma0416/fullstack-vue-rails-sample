import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import MatchedStandardsList from 'features/standards_assigning/MatchedStandardsList';
import {
  matchedStandards,
} from './standards_assigning_fixture.js';


function getWrapper() {
  return shallowMount(
    MatchedStandardsList,
    {
      global: {
        plugins: [
          createTestingPinia(
            {
              stubActions: false,
              initialState: {
                store: {
                  matchedStandards: null,
                  isFirstSearch: false,
                },
              },
            }
          ),
        ],
      },
    }
  );
}

describe(
  'MatchedStandardsList',
  () => {
    let wrapper;

    describe('with empty results', () => {
      beforeEach(
        () => {
          wrapper = getWrapper();
          wrapper.vm.store.matchedStandards = [];
          wrapper.vm.store.isSearchLoading = false;
        }
      );
      it('explains an empty result to the user', () => {
        expect(
          wrapper.find('.test-empty-matching-standards').text()
        ).toEqual('Adjust your filters and try again');
      });
    });
    describe('with non-empty results', () => {
      beforeEach(
        () => {
          wrapper = getWrapper();
          wrapper.vm.store.updateMatchedStandards(JSON.stringify(matchedStandards));
        }
      );
      it('displays the matched standards', () => {
        expect(
          wrapper.find('.test-matched-standard-label-0').text()
        ).toEqual(
          `parent number 1 ${matchedStandards[0].description}`
        );
        expect(
          wrapper.find('.test-matched-standard-label-1').text()
        ).toEqual(
          `${matchedStandards[1].number} ${matchedStandards[1].description}`
        );
      });

      it('displays the count of the matched standards', () => {
        expect(
          wrapper.find('.matching-standards-count').text()
        ).toEqual(`Matching Standards (${matchedStandards.length})`);
      });

      it('updates the store when standards are selected', async () => {
        await wrapper.find('.test-matched-standard-0').setChecked();
        expect(
          wrapper.vm.store.selectedStandards[0]
        ).toEqual(matchedStandards[0].vendor_guid);
      });
    });
  }
);
