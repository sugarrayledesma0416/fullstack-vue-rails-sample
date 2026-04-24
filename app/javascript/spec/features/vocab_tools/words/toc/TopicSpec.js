import { mount } from '@vue/test-utils';
import Topic from 'features/vocab_tools/words/toc/Topic';

const getProps = (topicName, selected, wordCount) => {
  return {
    lessonId: 11,
    lessonIndex: 0,
    level: 1,
    targetLanguageCode: 'fr',
    topic: {
      isEmpty: false,
      name: topicName,
      selected,
      wordCount,
    },
    topicIndex: 0,
    unitId: 1,
  };
};

let wrapper;
const getWrapper = (propsData) => mount(Topic, { propsData });

const getTopic1Checkbox = () => {
  return wrapper.get('.test-topic-Le_campus-checkbox');
};

const getTopic2Checkbox = () => {
  return wrapper.get('.test-topic-Les_personnes-checkbox');
};

describe('Topic', () => {
  describe('when topic has 2 words and is selecetd', () => {
    beforeEach(() => {
      const propsForSelectedTopic = getProps('Le campus', true, 2);
      wrapper = getWrapper(propsForSelectedTopic);
    });

    describe('when Topic is mounted', () => {
      it('displays a Topic "Le campus"', () => {
        expect(wrapper.get('.test-topic-Le_campus').text()).toBe('Le campus');
      });

      it('displays word count "2" for topic "Le campus"', () => {
        // text comes '2 words' but 'words' is only visible for screen reader
        expect(wrapper.get('.test-topic-Le_campus-word-count').text()).toContain('2');
      });

      it('displays checked checkbox for topic "Le campus"', () => {
        expect(getTopic1Checkbox().element.checked).toBeTruthy();
      });

      it('triggers event "toggleTopicSelection" when topic "Le campus" checkbox ' +
        'is clicked', async () => {
        const checkbox = getTopic1Checkbox();
        await checkbox.trigger('click');
        expect(wrapper.emitted('toggleTopicSelection')).toHaveLength(1);
      });
    });
  });

  describe('when topic has 3 words and is not selecetd', () => {
    beforeEach(() => {
      const propsForUnselectedTopic = getProps('Les personnes', false, 3);
      wrapper = getWrapper(propsForUnselectedTopic);
    });

    describe('when Topic is mounted', () => {
      it('displays a Topic "Les personnes"', () => {
        expect(wrapper.get('.test-topic-Les_personnes').text()).toBe('Les personnes');
      });

      it('displays word count "3" for topic "Les personnes"', () => {
        expect(wrapper.get('.test-topic-Les_personnes-word-count').text()).toContain('3');
      });

      it('displays unchecked checkbox for topic "Les personnes"', () => {
        expect(getTopic2Checkbox().element.checked).toBeFalsy();
      });

      it('triggers event "toggleTopicSelection" when topic "Les personnes" checkbox ' +
        'is clicked', async () => {
        const checkbox = getTopic2Checkbox();
        await checkbox.trigger('click');
        expect(wrapper.emitted('toggleTopicSelection')).toHaveLength(1);
      });
    });
  });
});
