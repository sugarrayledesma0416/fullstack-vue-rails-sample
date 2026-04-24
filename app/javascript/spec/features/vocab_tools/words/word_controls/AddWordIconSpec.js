import { mount } from '@vue/test-utils';
import AddWordIcon from 'features/vocab_tools/words/word_controls/AddWordIcon';

const props = {
  lesson: {
    id: 324,
    in_course: true,
    name: 'Lección 1 | Hola, ¿qué tal? ',
    selected: true,
  },
  totalColumns: 3,
  unit: {
    id: 303,
    in_course: true,
    name: 'Lección 1',
  },
};

const getWrapper = () => {
  return mount(AddWordIcon, { props });
};

describe('Vocab Tools Add User Defined Word Link', () => {
  describe('I can see Add Word link to add user defined word', () => {
    let wrapper;
    beforeEach(() => wrapper = getWrapper());

    it('displays "Add" music icon', () => {
      expect(wrapper.get(
        `.test-lesson-${props.lesson.id}-add-word`
      ).get('span').attributes().class).toContain('c-embedded-icon--add');
    });

    it('displays "Add Word" text over the button link', () => {
      expect(
        wrapper.get(`.test-lesson-${props.lesson.id}-add-word`).text()
      ).toContain('Add Word');
    });
  });
});
