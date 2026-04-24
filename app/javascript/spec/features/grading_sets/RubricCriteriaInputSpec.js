import { mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import RubricCriteriaInput
  from 'features/grading_sets/RubricCriteriaInput';
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
    RubricCriteriaInput,
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
        attemptId: '1',
        criteria: { title: 'Content', max_score: '5' },
        index: 2,
        userId: 1,
      },
    }
  );
}

describe('RubricCriteriaInput', () => {
  let wrapper;

  beforeEach(
    () => {
      wrapper = getWrapper();
    }
  );

  describe('Clicking into a criteria input', () => {
    it('Sets the focusedCriteriaIndex in the store', async () => {
      await wrapper.find('input').trigger('focus');
      expect(wrapper.vm.store.focusedCriteriaIndex).toBe(2);
    });

    // TODO fix these validation specs - validation happens when clicking save/done
    xit('does not allow negative values',
      async () => {
        const criteriaInput = wrapper.find('.test-rubric-criteria-input');
        criteriaInput.element.value = -1;
        criteriaInput.trigger('change');
        await wrapper.vm.$nextTick();

        expect(criteriaInput.element.value).toEqual('0');
      }
    );

    xit('does not allow values over max', async () => {
      const criteriaInput = wrapper.find('.test-rubric-criteria-input');
      criteriaInput.element.value = 6;
      criteriaInput.trigger('change');
      await wrapper.vm.$nextTick();
      expect(criteriaInput.element.value).toEqual(`${wrapper.vm.props.pointsPossible}`);
    });

    xit('does not allow non-number values', async () => {
    });

    xit('allows half points', async () => {
    });

    xit('does not allow commas', async () => {
    });
  });

  describe('When the earned points are updated', () => {
    it('Updates the criteria input value', async () => {
      wrapper.vm.store.earnedPoints[0].criteria['Content'].earned = 4;
      await wrapper.vm.$nextTick();
      const inputElm = wrapper.find('.test-criteria-input-Content');
      expect(inputElm.element.value).toEqual('4.0');
    });
  });
});
