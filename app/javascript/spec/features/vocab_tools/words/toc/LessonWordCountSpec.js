import { mount } from '@vue/test-utils';
import LessonWordCount from 'features/vocab_tools/words/toc/LessonWordCount';

const lessonWithTwoTopics = {
  lesson: {
    id: 11,
    selected: false,
    topics: [
      {
        selected: true,
        wordCount: 2,
      },
      {
        selected: false,
        wordCount: 3,
      },
    ],
  },
  level: 1,
};

let wrapper;
const getWrapper = (propsData) => mount(LessonWordCount, { propsData });

describe('LessonWordCount', () => {
  describe('when lesson has 2 topics', () => {
    beforeEach(() => {
      wrapper = getWrapper(lessonWithTwoTopics);
    });

    describe('when LessonWordCount is mounted', () => {
      it('displays selected word count info "2 out of 5" for lesson', () => {
        expect(wrapper.get('.test-lesson-word-count-info').text()).toBe('2/5');
      });
    });
  });
});
