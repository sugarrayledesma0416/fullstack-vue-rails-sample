import { mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import QuickGradeControls
  from 'features/grading_sets/QuickGradeControls';
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


function getWrapper(useStoreArg) {
  return mount(
    QuickGradeControls,
    {
      slots: { default: '<span class="test-default-slot" />' },
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
          useStore: useStoreArg,
        },
      },
      props: {
        score: useStoreArg().earnedPoints[0],
      },
    }
  );
}

describe('QuickGradeControls', () => {
  describe('When using rubric grading', () => {
    it('Shows the default slot', () => {
      const useStore = useGradingSetStore({ ...config, ...{ isInitRubricGraded: true }});
      const wrapper = getWrapper(useStore);
      expect(wrapper.find('.test-default-slot').exists()).toBe(true);
    });
    it('Clicking the 0% link sets criteria points to 0', async () => {
      const useStore = useGradingSetStore({ ...config, ...{ isInitRubricGraded: true }});
      const wrapper = getWrapper(useStore);
      wrapper.find('.test-quick-grade-no-points').trigger('click');
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.store.earnedPoints[0].criteria['Content'].earned).toEqual(0);
      expect(wrapper.vm.store.earnedPoints[0].criteria['Organization'].earned).toEqual(0);
      expect(wrapper.vm.store.earnedPoints[0].criteria['Accuracy'].earned).toEqual(0);
      expect(wrapper.vm.score.isNoPointsDisabled).toBeTruthy();
    });

    it('Clicking the 100% link sets the criteria points to their max allowed', async () => {
      const useStore = useGradingSetStore({ ...config, ...{ isInitRubricGraded: true }});
      const wrapper = getWrapper(useStore);
      // The fixture's max points are 5 across categories, which is typical.
      // Changing the max points here to test differing values, and prove that the correct
      // max point value is applied per criteria.
      wrapper.vm.store.earnedPoints[0].criteria['Organization'].max_score = 4;
      wrapper.vm.store.earnedPoints[0].criteria['Accuracy'].max_score = 3;

      wrapper.find('.test-quick-grade-full-points').trigger('click');
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.store.earnedPoints[0].criteria['Content'].earned).toEqual(5);
      expect(wrapper.vm.store.earnedPoints[0].criteria['Organization'].earned).toEqual(4);
      expect(wrapper.vm.store.earnedPoints[0].criteria['Accuracy'].earned).toEqual(3);
      expect(wrapper.vm.score.isFullPointsDisabled).toBeTruthy();
    });
  });

  describe('When using manual grading', () => {
    it('Does not show the default slot', () => {
      const useStore = useGradingSetStore({ ...config, ...{ isInitRubricGraded: false }});
      const wrapper = getWrapper(useStore);
      expect(wrapper.find('.test-default-slot').exists()).toBe(false);
    });

    it('Clicking the 0% link the total earned points to 0', async () => {
      const useStore = useGradingSetStore({ ...config, ...{ isInitRubricGraded: false }});
      const wrapper = getWrapper(useStore);
      wrapper.find('.test-quick-grade-no-points').trigger('click');
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.store.earnedPoints[0].totalPoints).toEqual(0)
    });

    it('Clicking the 100% link sets the total earned points to the points possible', async () => {
      const useStore = useGradingSetStore({ ...config, ...{ isInitRubricGraded: false }});
      const wrapper = getWrapper(useStore);

      wrapper.find('.test-quick-grade-full-points').trigger('click');
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.store.earnedPoints[0].totalPoints).toEqual(10);
    });
  });
});
