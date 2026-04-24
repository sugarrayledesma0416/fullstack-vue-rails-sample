import { mount } from '@vue/test-utils';
import VocabTabs from 'features/vocab_tools/words/VocabTabs';

describe('VocabTabs', () => {
  let wrapper;

  function getWrapper() {
    return mount(VocabTabs);
  }

  describe('on mounted', () => {
    let tabListElm;

    beforeEach(() => {
      wrapper = getWrapper();
      tabListElm = wrapper.get('.test-tab-list');
    });

    it('displays a tab labeled "Vocabulary', function() {
      const tabLinkElm = tabListElm.findAll('a')[0];
      expect(tabLinkElm.text()).toBe('Vocabulary');
    });

    it('displays the "Vocabulary" tab selected', function() {
      const tabLinkElm = tabListElm.findAll('a')[0];
      expect(tabLinkElm.classes()).toContain('is-selected');
    });

    it('displays a tab labeled "Flashcards', function() {
      const tabLinkElm = tabListElm.findAll('a')[1];
      expect(tabLinkElm.text()).toBe('Flashcards');
    });
  });
});
