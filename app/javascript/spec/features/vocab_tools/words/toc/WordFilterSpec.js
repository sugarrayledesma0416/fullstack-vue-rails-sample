import { shallowMount } from '@vue/test-utils';
import WordFilter from 'features/vocab_tools/words/toc/WordFilter';
const unitAssignedInCourse = {
  expanded: true,
  id: 1,
  inCourse: true,
  lessons: [
    {},
    {},
  ],
  name: 'Unité 1',
};
const unitNotAssignedInCourse = {
  expanded: true,
  id: 2,
  inCourse: false,
  lessons: [
    {},
    {},
    {},
  ],
  name: 'Unité 2',
};
const commmonProps = {
  targetLanguageCode: 'fr',
  units: [unitAssignedInCourse, unitNotAssignedInCourse],
  twoTier: false,
  viewAllLessons: true,
};

let wrapper;
const getWrapper = (propsData) => {
  return shallowMount(WordFilter, {
    propsData,
    stubs: ['LessonList', 'TopicList'],
  });
};

const triggerCompEvent = async (wrapper, compName, eventName) => {
  const comp = wrapper.findComponent({ name: compName });
  await comp.vm.$emit(eventName);
};

describe('WordFilter', () => {
  describe('when there are 2 units and one unit has 2 lessons and another has 3 lessons', () => {
    describe('when "twoTier" value is false', () => {
      beforeEach(() => {
        const singleTierProps = { ...commmonProps, ...{ twoTier: false }};
        wrapper = getWrapper(singleTierProps);
      });

      describe('when WordFilter is mounted', () => {
        it('displays 5 "TopicList" components one for each lesson', () => {
          expect(wrapper.findAllComponents({ name: 'TopicList' })).toHaveLength(5);
        });

        it('triggers event "toggleLessonSelection" when receives it ' +
          'from child component "TopicList"', async () => {
          await triggerCompEvent(wrapper, 'TopicList', 'toggleLessonSelection');
          expect(wrapper.emitted('toggleLessonSelection')).toHaveLength(1);
        });

        it('triggers event "toggleTopicSelection" when receives it ' +
          'from child component "TopicList"', async () => {
          await triggerCompEvent(wrapper, 'TopicList', 'toggleTopicSelection');
          expect(wrapper.emitted('toggleTopicSelection')).toHaveLength(1);
        });

        it('triggers event "toggleTopicSelection" when receives it ' +
          'from child component "TopicList"', async () => {
          await triggerCompEvent(wrapper, 'TopicList', 'toggleTopicSelection');
          expect(wrapper.emitted('toggleTopicSelection')).toHaveLength(1);
        });
      });
    });

    describe('when "twoTier" value is true', () => {
      beforeEach(() => {
        const twoTierProps = { ...commmonProps, ...{ twoTier: true }};
        wrapper = getWrapper(twoTierProps);
      });

      describe('when WordFilter is mounted', () => {
        it('displays 2 "LessonList" components one for each unit', () => {
          expect(wrapper.findAllComponents({ name: 'LessonList' })).toHaveLength(2);
        });

        it('triggers event "toggleLessonSelection" when receives it ' +
          'from child component "LessonList"', async () => {
          await triggerCompEvent(wrapper, 'LessonList', 'toggleLessonSelection');
          expect(wrapper.emitted('toggleLessonSelection')).toHaveLength(1);
        });

        it('triggers event "retrieveLesson" when receives it ' +
          'from child component "LessonList"', async () => {
          await triggerCompEvent(wrapper, 'LessonList', 'retrieveLesson');
          expect(wrapper.emitted('retrieveLesson')).toHaveLength(1);
        });

        it('triggers event "toggleTopicSelection" when receives it ' +
          'from child component "LessonList"', async () => {
          await triggerCompEvent(wrapper, 'LessonList', 'toggleTopicSelection');
          expect(wrapper.emitted('toggleTopicSelection')).toHaveLength(1);
        });
      });
    });

    describe('when some lessons are not in-course', () => {
      describe('when viewAllLessons is true', () => {
        beforeEach(() => {
          const propsData = { ...commmonProps, ...{ viewAllLessons: true }};
          wrapper = getWrapper(propsData);
        });

        describe('when WordFilter is mounted', () => {
          it('displays 5 "TopicList" components one for each lesson', () => {
            expect(wrapper.findAllComponents({ name: 'TopicList' })).toHaveLength(5);
          });
        });
      });

      describe('when viewAllLessons is false', () => {
        beforeEach(() => {
          const propsData = { ...commmonProps, ...{ viewAllLessons: false }};
          wrapper = getWrapper(propsData);
        });

        describe('when WordFilter is mounted', () => {
          it('displays 2 "TopicList" components one for each in-course lesson', () => {
            expect(wrapper.findAllComponents({ name: 'TopicList' })).toHaveLength(2);
          });
        });
      });
    });
  });
});
