import { shallowMount } from '@vue/test-utils';
import TopicList from 'features/vocab_tools/words/toc/TopicList';

VHL = { Music: { V1: {}}};
VHL.Music.V1.Disclosure = jest.fn(() => {});

const lessonWithTwoTopics = {
  lesson: {
    displayName: 'Leçon 1A',
    expanded: true,
    id: 11,
    inCourse: true,
    selected: false,
    topics: [
      {},
      {},
    ],
  },
  lessonIndex: 0,
  level: 1,
  targetLanguageCode: 'fr',
  unitId: 1,
};

let wrapper;
const getWrapper = (propsData) => {
  return shallowMount(TopicList, {
    propsData,
    stubs: ['Topic', 'LessonWordCount'],
  });
};

const getLessonLabel = () => {
  return wrapper.get('.test-lesson-display-name-11');
};

const getLessonCheckbox = () => {
  return wrapper.get('.test-lesson-11-name');
};

describe('TopicList', () => {
  describe('when lesson has 2 topics', () => {
    beforeEach(() => {
      wrapper = getWrapper(lessonWithTwoTopics);
    });

    describe('when TopicList is mounted', () => {
      it('calls VHL.Music.V1.Disclosure constructor', () => {
        expect(VHL.Music.V1.Disclosure).toHaveBeenCalledTimes(1);
      });

      it('displays topic list disclosure', () => {
        expect(wrapper.find('.test-topic-list-disclosure').exists()).toBeTruthy();
      });

      it('displays a lesson "Leçon 1A"', () => {
        expect(getLessonLabel().text()).toBe('Leçon 1A');
      });

      it('displays 1 "LessonWordCount" component for the lesson', () => {
        expect(wrapper.findAllComponents({ name: 'LessonWordCount' })).toHaveLength(1);
      });

      it('displays 2 "Topic" components one for each topic', () => {
        expect(wrapper.findAllComponents({ name: 'Topic' })).toHaveLength(2);
      });

      it('displays "Select all" as first item under lesson disclosure', () => {
        expect(
          wrapper.get('.test-disclosure-body-lesson-11 li').classes('test-lesson-11-select-all')
        ).toBeTruthy();
      });

      it('displays a checkbox for the lesson with text "Select all"', () => {
        expect(wrapper.get('.test-lesson-11-name+label').text()).toBe('Select all');
      });

      it('displays unchecked checkbox for the lesson', () => {
        expect(getLessonCheckbox().element.checked).toBeFalsy();
      });

      it('triggers event "toggleLessonSelection" when lesson level checkbox ' +
        'is clicked', async () => {
        const checkbox = getLessonCheckbox();
        await checkbox.trigger('click');
        expect(wrapper.emitted('toggleLessonSelection')).toHaveLength(1);
      });

      it('triggers event "retrieveLesson" when lesson disclosure button ' +
        'is clicked', async () => {
        const disclosureButton = wrapper.get('.test-disclosure-lesson-opener');
        await disclosureButton.trigger('click');
        expect(wrapper.emitted('retrieveLesson')).toHaveLength(1);
      });

      it('triggers event "toggleTopicSelection" when receives it ' +
        'from child component "Topic"', async () => {
        const comp = wrapper.findComponent({ name: 'Topic' });
        await comp.vm.$emit('toggleTopicSelection');
        expect(wrapper.emitted('toggleTopicSelection')).toHaveLength(1);
      });
    });
  });

  describe('when lesson has 2 topics and lesson is selected', () => {
    beforeEach(() => {
      // setting props.lesson.selected = true and keeping rest of the values as is
      const selectedLessonWithTwoTopics = {
        ...lessonWithTwoTopics,
        lesson: { ...lessonWithTwoTopics.lesson, ...{ selected: true }},
      };
      wrapper = getWrapper(selectedLessonWithTwoTopics);
    });

    describe('when TopicList is mounted', () => {
      it('displays a lesson "Leçon 1A"', () => {
        expect(getLessonLabel().text()).toBe('Leçon 1A');
      });

      it('displays a checked checkbox for the lesson', () => {
        expect(getLessonCheckbox().element.checked).toBeTruthy();
      });
    });
  });
});
