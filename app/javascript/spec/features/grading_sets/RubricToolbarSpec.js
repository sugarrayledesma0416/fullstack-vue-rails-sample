import { mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import RubricToolbar from 'features/grading_sets/RubricToolbar';
import {
  criteriasWithOrderedPerformances,
  criteriaColumnHeaders,
  userScoresWithRubric,
  userScoresWithManual,
  userScoresWithEmptyScores,
} from './rubric_fixture.js';
import useGradingSetStore
  from 'features/grading_sets/models/use_grading_set_store.js';

const config = {
  rubricColumnHeaders: JSON.parse(criteriaColumnHeaders),
  rubricCriterias: JSON.parse(criteriasWithOrderedPerformances),
  isInitRubricGraded: true,
  pointsPossible: 10,
  scores: JSON.parse(userScoresWithEmptyScores),
};

const useStore = useGradingSetStore(config);

function getWrapper() {
  return mount(
    RubricToolbar,
    {
      global: {
        plugins: [
          createTestingPinia(
            {
              stubActions: false,
              initialState: {},
            }
          ),
        ],
        provide: {
          useStore: useStore,
        },
      },
      props: {
      },
    }
  );
}

describe('RubricToolbar', () => {
  let wrapper;

  beforeEach(
    () => {
      wrapper = getWrapper();
    }
  );

  describe('Toolbar initialization', () => {
    it('Does not show the toolbar', () => {
      expect(wrapper.find('.test-rubric-toolbar-table').exists()).toBe(false);
    });
  });

  describe('When the focusedCriteriaIndex is updated', () => {
    it('displays the corresponding rubric table row', async () => {
      // This happens when a user clicks into a RubricCriteriaInput
      wrapper.vm.store.focusedCriteriaIndex = 1;
      await wrapper.vm.$nextTick();
      expect(wrapper.find('.test-rubric-toolbar-table').exists()).toBe(true);
      expect(wrapper.find('.test-rubric-toolbar-col-headers').exists()).toBe(true);
      expect(wrapper.find('.test-rubric-toolbar-criteria-title').text()).toBe('Organization');
      expect(
        wrapper.find('.test-rubric-toolbar-description-0').text()
      ).toBe(
        'The brochure is well organized and visually engaging, with various attractive visuals.'
      );
    });

    describe('When the value is changed to null', () => {
      it('hides the rubric toolbar', async () => {
        // This happens when a user changes grading methods from rubric to manual
        wrapper.vm.store.focusedCriteriaIndex = 1;
        await wrapper.vm.$nextTick();
        wrapper.vm.store.focusedCriteriaIndex = null;
        await wrapper.vm.$nextTick();

        expect(wrapper.find('.test-rubric-toolbar-table').exists()).toBe(false);
      });
    });
  });

  describe('When a criteria score column is clicked', () => {
    it('Updates the criteria earned points', async () => {
      wrapper.vm.store.focusedCriteriaIndex = 0;
      wrapper.vm.store.focusedUserId = 1;
      await wrapper.vm.$nextTick();
      wrapper.find('.test-rubric-toolbar-description-0').trigger('click');
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.store.earnedPoints[0].criteria['Content'].earned).toEqual(5);
    });
  });
});
