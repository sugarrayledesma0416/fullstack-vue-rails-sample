import { mount } from '@vue/test-utils';
import LessonHeaderRow from 'features/vocab_tools/words/table/LessonHeaderRow';

let wrapper;
const getWrapper = (propsData) => mount(LessonHeaderRow, { propsData });

describe('LessonHeaderRow', () => {
  beforeEach(() => {
    const props = {
      lesson: { name: 'Lección 1 | Hola, ¿qué tal?' },
      targetLanguageCode: 'Fr',
    };
    wrapper = getWrapper(props);
  });

  describe('when LessonHeaderRow is mounted', () => {
    it('displays lesson name "Lección 1 | Hola, ¿qué tal?"', () => {
      expect(wrapper.get('.test-lesson-name').text()).toBe('Lección 1 | Hola, ¿qué tal?');
    });

    it('displays lesson label with lang attribute "fr"', () => {
      expect(wrapper.get('.test-lesson-name').attributes('lang')).toBe('Fr');
    });
  });
});
