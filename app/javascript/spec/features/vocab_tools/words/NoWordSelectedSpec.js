import { mount } from '@vue/test-utils';
import NoWordSelected from 'features/vocab_tools/words/NoWordSelected';

describe('NoWordSelected', () => {
  let wrapper;

  const getWrapper = () => {
    return mount(NoWordSelected, {
      global: {
        provide: {
          magnifyingGlassIconPath: '',
        }
      }
    });
  }

  describe('on mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays text "You have no words selected."', () => {
      expect(wrapper.get('.test-no-words-selected__msg').text()).toBe(
        'You have no words selected.'
      );
    });
  });
});
