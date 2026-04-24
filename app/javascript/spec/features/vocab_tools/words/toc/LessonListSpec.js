import { shallowMount } from '@vue/test-utils';
import LessonList from 'features/vocab_tools/words/toc/LessonList';

VHL = { Music: { V1: {}}};
VHL.Music.V1.Disclosure = jest.fn(() => {});

const unitWithTwoLessons = {
  targetLanguageCode: 'fr',
  unit: {
    expanded: true,
    id: 1,
    lessons: [
      {},
      {},
    ],
    name: 'Unité 1',
    inCourse: true,
  },
  viewAllLessons: true,
};

describe('LessonList', () => {
  let wrapper;
  const getWrapper = (propsData) => {
    return shallowMount(LessonList, {
      propsData,
      stubs: ['TopicList', 'UnitWordCount'],
    });
  };

  const triggerCompEvent = async (compName, eventName) => {
    const comp = wrapper.findComponent({ name: compName });
    await comp.vm.$emit(eventName);
  };

  describe('when unit has 2 lessons', () => {
    beforeEach(() => {
      wrapper = getWrapper(unitWithTwoLessons);
    });

    describe('when LessonList is mounted', () => {
      it('calls VHL.Music.V1.Disclosure constructor', () => {
        expect(VHL.Music.V1.Disclosure).toHaveBeenCalledTimes(1);
      });

      it('displays lesson list disclosure', () => {
        expect(wrapper.find('.test-lesson-list-disclosure').exists()).toBeTruthy();
      });

      it('displays a unit "Unité 1"', () => {
        expect(wrapper.get('.test-unit-name-1').text()).toBe('Unité 1');
      });

      it('displays 1 "UnitWordCount" component for the unit', () => {
        expect(wrapper.findAllComponents({ name: 'UnitWordCount' })).toHaveLength(1);
      });

      it('displays 2 "TopicList" components one for each lesson', () => {
        expect(wrapper.findAllComponents({ name: 'TopicList' })).toHaveLength(2);
      });

      it('triggers event "toggleLessonSelection" when receives it ' +
        'from child component "TopicList"', async () => {
        await triggerCompEvent('TopicList', 'toggleLessonSelection');
        expect(wrapper.emitted('toggleLessonSelection')).toHaveLength(1);
      });

      it('triggers event "retrieveLesson" when receives it ' +
        'from child component "TopicList"', async () => {
        await triggerCompEvent('TopicList', 'retrieveLesson');
        expect(wrapper.emitted('retrieveLesson')).toHaveLength(1);
      });

      it('triggers event "toggleTopicSelection" when receives it ' +
        'from child component "TopicList"', async () => {
        await triggerCompEvent('TopicList', 'toggleTopicSelection');
        expect(wrapper.emitted('toggleTopicSelection')).toHaveLength(1);
      });
    });
  });
});
