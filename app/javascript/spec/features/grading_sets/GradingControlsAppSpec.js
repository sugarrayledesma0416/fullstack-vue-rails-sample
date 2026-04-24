import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { isDeepStrictEqual } from 'util';
import GradingControlsApp
  from 'features/grading_sets/GradingControlsApp';
import {
  criteriasWithOrderedPerformances,
  criteriaColumnHeaders,
  rubricLinkJson,
  userScoresWithRubric,
  userScoresWithManual,
  userScoresWithEmptyScores,
} from './rubric_fixture.js';

const props = {
  rubricColumnHeaders: criteriaColumnHeaders,
  rubricCriterias: criteriasWithOrderedPerformances,
  viewRubricLink: rubricLinkJson,
  gradePending: 'true',
  pointsPossible: '5',
  rubricGraded: 'true',
  userScores: userScoresWithEmptyScores,
};

function getWrapper(propArg) {
  return shallowMount(
    GradingControlsApp,
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
      },
      props: propArg,
    }
  );
}

describe('onMounted sessionStorage calls', () => {
  afterEach(
    () => {
      sessionStorage.removeItem('showGradingMethodModal');
    }
  );

  it('sets sessionStorage showGradingMethodModal if not yet defined', () => {
    sessionStorage.removeItem('showGradingMethodModal');
    getWrapper(props);
    expect(sessionStorage.getItem('showGradingMethodModal')).toEqual('true');
  });

  it('does not change sessionStorage showGradingMethodModal if defined', () => {
    sessionStorage.setItem('showGradingMethodModal', 'false');
    getWrapper(props);
    expect(sessionStorage.getItem('showGradingMethodModal')).toEqual('false');
  });
});


describe('GradingControlsApp slots', () => {
  // The student names respond to js bound to a checkbox
  // outside of this app for showing/hiding. This test makes
  // sure that they are present with the necessary classes.
  it('Implements a student name slot', () => {
    const slotsWrapper = shallowMount(
      GradingControlsApp,
      {
        global: {
          stubs: {
            GradingInputs: false,
          },
          plugins: [
            createTestingPinia(
              {
                stubActions: true,
                initialState: {},
              }
            ),
          ],
        },
        props: props,
      }
    );
    const name = slotsWrapper.find('.student_name');
    const number = slotsWrapper.find('.student_number');
    expect(name.exists()).toBe(true);
    expect(number.exists()).toBe(true);
  });
});

describe('GradingControlsApp', () => {
  let wrapper;

  beforeEach(
    () => {
      wrapper = getWrapper(props);
    }
  );

  afterEach(
    () => {
      sessionStorage.removeItem('showGradingMethodModal');
      sessionStorage.removeItem('gradingMethod');
    }
  );

  describe('Grading store initialization', () => {
    describe('When the gradingMethod session storage is set to manual', () => {
      beforeEach(() => {
        sessionStorage.setItem('gradingMethod', 'manual');
      });
      describe('When the grade is pending', () => {
        // note: when the grade is pending, props.rubricGraded will be false
        it('it initializes isRubricGraded: false', () => {
          wrapper = getWrapper({ ...props, ...{ rubricGraded: 'false', gradePending: 'true' }});
          expect(wrapper.vm.store.isRubricGraded).toBe(false);
        });
      });

      describe('When the grade is not pending', () => {
        // The activity has already been graded, either via rubric or manual method.
        beforeEach(() => {
          props.gradePending = 'false';
        });
        it('it initializes isRubricGraded: false, when it was scored manually', () => {
          wrapper = getWrapper({ ...props, ...{ rubricGraded: 'false' }});
          expect(wrapper.vm.store.isRubricGraded).toBe(false);
        });
        it('it initializes isRubricGraded: true, when grading was scored via rubric', () => {
          wrapper = getWrapper({ ...props, ...{ rubricGraded: 'true' }});
          expect(wrapper.vm.store.isRubricGraded).toBe(true);
        });
      });
    });

    describe('When the gradingMethod session storage is set to rubric', () => {
      beforeEach(() => {
        sessionStorage.setItem('gradingMethod', 'rubric');
      });

      describe('When the grade is pending', () => {
        // note: when the grade is pending, props.rubricGraded will be false
        it('it initializes with isRubricGraded: true', () => {
          wrapper = getWrapper({ ...props, ...{ rubricGraded: 'false', gradePending: 'true' }});
          expect(wrapper.vm.store.isRubricGraded).toBe(true);
        });
      });

      describe('When the grade is not pending', () => {
        // The activity has already been graded, either via rubric or manual method.
        beforeEach(() => {
          props.gradePending = 'false';
        });
        it('it initializes with isRubricGraded: false, when it was scored manually', () => {
          wrapper = getWrapper({ ...props, ...{ rubricGraded: 'false' }});
          expect(wrapper.vm.store.isRubricGraded).toBe(false);
        });
        it('it initializes with isRubricGraded: true, when grading was scored via rubric', () => {
          wrapper = getWrapper({ ...props, ...{ rubricGraded: 'true' }});
          expect(wrapper.vm.store.isRubricGraded).toBe(true);
        });
      });
    });

    describe('When the gradingMethod session storage is not set', () => {
      describe('When the grade is pending', () => {
        // note: when the grade is pending, props.rubricGraded will be false
        it('it initializes with isRubricGraded: true', () => {
          wrapper = getWrapper({ ...props, ...{ rubricGraded: 'false', gradePending: 'true' }});
          expect(wrapper.vm.store.isRubricGraded).toBe(true);
        });
      });

      describe('When the grade is not pending', () => {
        // The activity has already been graded, either via rubric or manual method.
        beforeEach(() => {
          props.gradePending = 'false';
        });

        describe('When the rubricGraded prop is false', () => {
          it('initializes with isRubricGraded: false', () => {
            wrapper = getWrapper({ ...props, ...{ rubricGraded: 'false' }});
            expect(wrapper.vm.store.isRubricGraded).toBe(false);
          });
        });
        describe('When the rubricGraded prop is true', () => {
          it('initializes with isRubricGraded: true', () => {
            wrapper = getWrapper({ ...props, ...{ rubricGraded: 'true' }});
            expect(wrapper.vm.store.isRubricGraded).toBe(true);
          });
        });
      });
    });
  });

  describe('With a chat type activity', () => {
    it('Shows multi-user specific styling', () => {
      wrapper = getWrapper(
        {
          ...props,
          ...{ chatType: 'true' },
        }
      );
      expect(wrapper.find('.c-multi-user-question').exists()).toBe(true);
    });
  });

  describe('Changing the grading method', () => {
    describe('When the suppress change scores modal flag is false', () => {
      it('Displays the Clear Scores warning modal', async () => {
        wrapper = getWrapper(props);
        wrapper.find('.test-change-grading-method').setValue('rubric');
        await wrapper.vm.$nextTick();
        expect(wrapper.findComponent({ name: 'ClearScoresModal' }).isVisible()).toBe(true);
      });
    });

    describe('When the suppress change scores modal flag is true', () => {
      it('clears the scores and toggles the grading controls', async () => {
        wrapper = getWrapper({ ...props, ...{ userScores: userScoresWithRubric }});
        wrapper.vm.suppressClearScoresModal = true;
        wrapper.find('.test-change-grading-method').setValue('rubric');
        await wrapper.vm.$nextTick();
        const expected = {
          userId: 1,
          attemptId: 1,
          studentName: 'Fooname Barname',
          commentBoxSelector: '.js-comment-for-question_1-student-1',
          isInstructor: false,
          isPracticing: false,
          isGradable: true,
          inputName: 'score_for_question_1_student_1',
          criteria: {
            Content: { earned: null, max_score: 5 },
            Organization: { earned: null, max_score: 5 },
            Accuracy: { earned: null, max_score: 5 },
          },
          totalPoints: undefined,
        };
        expect(isDeepStrictEqual(wrapper.vm.store.earnedPoints[0], expected)).toBe(true);
      });
      it('sets gradingMethod to rubric in session storage when selecting rubric', async () => {
        // this will init with rubic grading
        wrapper = getWrapper({ ...props, ...{ userScores: userScoresWithRubric }});
        wrapper.vm.suppressClearScoresModal = true;
        wrapper.find('.test-change-grading-method').setValue('manual');
        await wrapper.vm.$nextTick();
        expect(sessionStorage.getItem('gradingMethod')).toEqual('manual');
      });
      it('sets gradingMethod to manual in session storage when selecting rubric', async () => {
        // set up to init with manual grading
        wrapper = getWrapper({ ...props, ...{ gradePending: 'false', rubricGraded: 'false' }});
        wrapper.vm.suppressClearScoresModal = true;
        wrapper.find('.test-change-grading-method').setValue('rubric');
        await wrapper.vm.$nextTick();
        expect(sessionStorage.getItem('gradingMethod')).toEqual('rubric');
      });
    });
  });

  describe('Closing the Clear Scores modal', () => {
    it('Hides the modal', async () => {
      wrapper.vm.showClearScoresModal = true;
      await wrapper.vm.$nextTick();
      wrapper.findComponent(
        { name: 'ClearScoresModal' }
      ).vm.$emit('close-clear-scores-modal', false);
      await wrapper.vm.$nextTick();
      expect(wrapper.findComponent({ name: 'ClearScoresModal' }).exists()).toBe(false);
    });

    it("Updates the 'Don't ask me again' flags", async () => {
      wrapper.vm.showClearScoresModal = true;
      await wrapper.vm.$nextTick();
      wrapper.findComponent(
        { name: 'ClearScoresModal' }
      ).vm.$emit('close-clear-scores-modal', true);
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.suppressClearScoresModal).toBe(true);
      expect(sessionStorage.getItem('showGradingMethodModal')).toBe('false');
    });

    it('clears the earned points', async () => {
      wrapper.vm.showClearScoresModal = true;
      await wrapper.vm.$nextTick();
      wrapper.findComponent(
        { name: 'ClearScoresModal' }
      ).vm.$emit('toggleGradingMethod', false);
      await wrapper.vm.$nextTick();
      const expectedMap = {
        userId: 1,
        attemptId: 1,
        studentName: 'Fooname Barname',
        commentBoxSelector: '.js-comment-for-question_1-student-1',
        isInstructor: false,
        isPracticing: null,
        isGradable: true,
        inputName: 'score_for_question_1_student_1',
        criteria: {
          Content: { earned: null, max_score: 5 },
          Organization: { earned: null, max_score: 5 },
          Accuracy: { earned: null, max_score: 5 },
        },
        totalPoints: undefined,
      };
      expect(isDeepStrictEqual(wrapper.vm.store.earnedPoints[0], expectedMap)).toBe(true);
    });
  });

  describe('Store initialization', () => {
    describe('When there are no existing scores', () => {
      it('Creates the points mapping', () => {
        const expectedMap = {
          userId: 1,
          attemptId: 1,
          studentName: 'Fooname Barname',
          commentBoxSelector: '.js-comment-for-question_1-student-1',
          isInstructor: false,
          isPracticing: null,
          isGradable: true,
          inputName: 'score_for_question_1_student_1',
          criteria: {
            Content: { earned: null, max_score: 5 },
            Organization: { earned: null, max_score: 5 },
            Accuracy: { earned: null, max_score: 5 },
          },
          totalPoints: undefined,
        };
        wrapper = getWrapper(props);
        expect(isDeepStrictEqual(wrapper.vm.store.earnedPoints[0], expectedMap)).toBe(true);
      });
    });
    describe('When there are existing rubric scores', () => {
      it('Creates the points mapping', () => {
        const expectedMap = {
          userId: 1,
          attemptId: 1,
          studentName: 'Fooname Barname',
          commentBoxSelector: '.js-comment-for-question_1-student-1',
          isInstructor: false,
          isPracticing: false,
          isGradable: true,
          inputName: 'score_for_question_1_student_1',
          criteria: {
            Content: { earned: 1, max_score: 5 },
            Organization: { earned: 2, max_score: 5 },
            Accuracy: { earned: 3, max_score: 5 },
          },
          totalPoints: 6,
        };
        wrapper = getWrapper(
          {
            ...props,
            ...{ userScores: userScoresWithRubric },
          }
        );
        expect(isDeepStrictEqual(wrapper.vm.store.earnedPoints[0], expectedMap)).toBe(true);
      });
    });
    describe('When there is an existing manual score', () => {
      it('Creates the points mapping', () => {
        const expectedMap = {
          userId: 1,
          attemptId: 1,
          studentName: 'Fooname Barname',
          commentBoxSelector: '.js-comment-for-question_1-student-1',
          isInstructor: false,
          isPracticing: null,
          isGradable: true,
          inputName: 'score_for_question_1_student_1',
          criteria: {
            Content: { earned: null, max_score: 5 },
            Organization: { earned: null, max_score: 5 },
            Accuracy: { earned: null, max_score: 5 },
          },
          totalPoints: 14,
        };
        wrapper = getWrapper(
          {
            ...props,
            ...{ userScores: userScoresWithManual },
            ...{ rubricGraded: 'false' },
          }
        );
        expect(isDeepStrictEqual(wrapper.vm.store.earnedPoints[0], expectedMap)).toBe(true);
      });
    });
  });
});
