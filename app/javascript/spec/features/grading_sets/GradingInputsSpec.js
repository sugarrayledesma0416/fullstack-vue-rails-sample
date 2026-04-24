import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import GradingInputs
  from 'features/grading_sets/GradingInputs';
import {
  criteriasWithOrderedPerformances,
  criteriaColumnHeaders,
  userScoresWithRubric,
  userScoresWithManual,
  userScoresWithEmptyScores,
  userScoresWithInstructor,
  userScoresNotGradable,
  userScoresPracticing,
} from './rubric_fixture.js';
import useGradingSetStore
  from 'features/grading_sets/models/use_grading_set_store.js';

let useStore;
let wrapper;

const props = {
  pointsPossible: '5',
  userId: 1,
  isChatType: false,
};

const config = {
  rubricColumnHeaders: JSON.parse(criteriaColumnHeaders),
  rubricCriterias: JSON.parse(criteriasWithOrderedPerformances),
  pointsPossible: 10,
  scores: JSON.parse(userScoresWithEmptyScores),
};

function getWrapper(useStoreArg, propsArg = props) {
  return shallowMount(
    GradingInputs,
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
          useStore: useStoreArg,
        },
      },
      props: propsArg,
    }
  );
}

describe('GradingInputs', () => {
  describe('With a chat type activity', () => {
    it('Shows multi-user specific styling', () => {
      useStore = useGradingSetStore({ ...config, ...{ isInitRubricGraded: true }});
      const propsArg = { ...props, ...{ isChatType: true }};
      wrapper = getWrapper(useStore, propsArg);
      expect(wrapper.find('.c-multi-user-question__user').exists()).toBe(true);
    });
  });
  describe('With an instructor user', () => {
    it('Displays a message instead of inputs', () => {
      const instructorJSON = { ...config, ...{ scores: JSON.parse(userScoresWithInstructor) }};
      const instructorConfig = { ...instructorJSON, ...{ isInitRubricGraded: true }};
      useStore = useGradingSetStore(instructorConfig);
      const propsArg = { ...props, ...{ isChatType: true }};
      wrapper = getWrapper(useStore, propsArg);

      // assert msg is displayed
      expect(
        wrapper.find('.test-user-inputs-1 .cannot_grade_explanation').text()
      ).toBe('Instructors cannot be graded.');

      // assert both rubric and manual inputs are hidden
      expect(wrapper.findComponent({ name: 'RubricCriteriaInput' }).exists()).toBe(false);
      expect(wrapper.find('.c-grading-scores__input--manual').isVisible()).toBe(false);
    });
  });
  describe('With a non-gradable student', () => {
    it('Displays a message instead of inputs', () => {
      const notGradableJSON = { ...config, ...{ scores: JSON.parse(userScoresNotGradable) }};
      const notGradableConfig = { ...notGradableJSON, ...{ isInitRubricGraded: true }};
      useStore = useGradingSetStore(notGradableConfig);
      wrapper = getWrapper(useStore);

      // assert msg is displayed
      expect(
        wrapper.find('.test-user-inputs-1 .cannot_grade_explanation').text()
      ).toBe('You cannot grade this student because they are not in your section.');

      // assert both rubric and manual inputs are hidden
      expect(wrapper.findComponent({ name: 'RubricCriteriaInput' }).exists()).toBe(false);
      expect(wrapper.find('.c-grading-scores__input--manual').isVisible()).toBe(false);
    });
  });
  describe('With a practicing student', () => {
    it('Displays a message instead of inputs', () => {
      const practicingJSON = { ...config, ...{ scores: JSON.parse(userScoresPracticing) }};
      const practicingConfig = { ...practicingJSON, ...{ isInitRubricGraded: true }};
      useStore = useGradingSetStore(practicingConfig);
      wrapper = getWrapper(useStore);

      // assert msg is displayed
      expect(
        wrapper.find('.test-user-inputs-1 .cannot_grade_explanation').text()
      ).toBe("This student completed the activity as 'practice', and therefore cannot be graded.");

      // assert both rubric and manual inputs are hidden
      expect(wrapper.findComponent({ name: 'RubricCriteriaInput' }).exists()).toBe(false);
      expect(wrapper.find('.c-grading-scores__input--manual').isVisible()).toBe(false);

      // assert hidden form field is present
      const hidden = wrapper.find('input[name="practice_mode[1]"]');
      expect(hidden.exists()).toBe(true);
      expect(hidden.element.value).toBe('true');
    });
  });
  describe('comment boxes', () => {
    it('Moves comment box to the GradingInput component for the correct user', () => {
      /* the comment box is rendered via rails outside of GradingControlsApp's scope.
       * For spec setup, append it to the body before booting Vue app.
       */
      const comment = document.createElement('div');
      comment.classList.add('js-comment-for-question_1-student-1');
      document.body.append(comment);
      useStore = useGradingSetStore({ ...config, ...{ isInitRubricGraded: true }});
      wrapper = getWrapper(useStore);
      expect(wrapper.find('.js-comment-for-question_1-student-1').exists()).toBe(true);
    });
  });
  describe('Input initialization', () => {
    describe('With a gradable student', () => {
      describe('When the rubricGradingMethod is true in the store', () => {
        it('initializes with the rubric controls & quick grade', () => {
          useStore = useGradingSetStore({ ...config, ...{ isInitRubricGraded: true }});
          wrapper = getWrapper(useStore);
          expect(wrapper.findComponent({ name: 'QuickGradeControls' }).isVisible()).toBe(true);
          expect(wrapper.findComponent({ name: 'RubricCriteriaInput' }).isVisible()).toBe(true);
          expect(wrapper.find('.c-grading-scores--rubric').exists()).toBe(true);
          expect(wrapper.find('.c-grading-scores--manual').exists()).toBe(false);
          expect(wrapper.find('.test-manual-input').isVisible()).toBe(false);
        });
      });
      describe('When the rubricGradingMethod is false in the store', () => {
        it('initializes with the manual controls & quick grade', () => {
          useStore = useGradingSetStore({ ...config, ...{ isInitRubricGraded: false }});
          wrapper = getWrapper(useStore);
          expect(wrapper.find('.c-grading-scores--rubric').exists()).toBe(false);
          expect(wrapper.find('.c-grading-scores--manual').exists()).toBe(true);
          expect(wrapper.findComponent({ name: 'RubricCriteriaInput' }).exists()).toBe(false);
          expect(wrapper.find('.test-manual-input').element).toBeVisible();
          expect(wrapper.findComponent({ name: 'QuickGradeControls' }).isVisible()).toBe(true);
        });
      });
    });
    describe('With a not gradable student', () => {
      describe('When the rubricGradingMethod is true in the store', () => {
        it('initializes with no rubric inputs and no quick grade controls', () => {
          const notGradableJSON = { ...config, ...{ scores: JSON.parse(userScoresNotGradable) }};
          const notGradableConfig = { ...notGradableJSON, ...{ isInitRubricGraded: true }};
          useStore = useGradingSetStore(notGradableConfig);
          wrapper = getWrapper(useStore);
          expect(wrapper.findComponent({ name: 'RubricCriteriaInput' }).exists()).toBe(false);
          expect(wrapper.find('.test-manual-input').isVisible()).toBe(false);
          expect(wrapper.findComponent({ name: 'QuickGradeControls' }).exists()).toBe(false);
        });
      });
      describe('When the rubricGradingMethod is false in the store', () => {
        it('initializes with no manual input and no quick grade controls', () => {
          const notGradableJSON = { ...config, ...{ scores: JSON.parse(userScoresNotGradable) }};
          const notGradableConfig = { ...notGradableJSON, ...{ isInitRubricGraded: false }};
          useStore = useGradingSetStore(notGradableConfig);
          wrapper = getWrapper(useStore);
          expect(wrapper.findComponent({ name: 'RubricCriteriaInput' }).exists()).toBe(false);
          expect(wrapper.find('.test-manual-input').isVisible()).toBe(false);
          expect(wrapper.findComponent({ name: 'QuickGradeControls' }).exists()).toBe(false);
        });
      });
    });
  });
});
