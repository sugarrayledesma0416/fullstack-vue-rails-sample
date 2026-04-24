import { mount } from '@vue/test-utils';
import NewWord from 'features/vocab_tools/words/word_controls/NewWord';
import { getHtmlDocument } from '../../../../support/utils';
import { metaTagContent } from 'music';

jest.mock('music', () => {
  const originalModule = jest.requireActual('music');
  return {
    __esModule: true,
    ...originalModule,
    metaTagContent: jest.fn(),
  };
});

metaTagContent.mockReturnValue('true');

VHL = VHL || {};

function setAccentBarComponentMock() {
  VHL.AccentBarComponent = jest.fn();
  VHL.AccentBarComponent.prototype = {
    register: jest.fn(),
    deactivateAll: jest.fn(),
  };
}

let wrapper;

const props = {
  lesson: {
    id: 324,
    in_course: true,
    name: 'Lección 1 | Hola, ¿qué tal? ',
    selected: true,
  },
  targetLanguage: 'Spanish',
  unit: {
    id: 303,
    in_course: true,
    name: 'Lección 1',
  },
  vocabHasDefinition: false,
};

const getWrapper = (props) => {
  return mount(NewWord, { props });
};

jest.mock('features/vocab_tools/words/word_controls/use_user_defined_word', () => {
  return jest.fn().mockImplementation(() => {
    return {
      attachToAccentBarEvents: jest.fn(),
      detachFromAccentBarEvents: jest.fn(),
      registerAccentBar: jest.fn().mockImplementation((accentBar) => {
        accentBar.register();
      }),
      metaData: {
        targetLanguageCode: 'es',
        programId: 79,
      },
    };
  });
});

const htmlDOM = getHtmlDocument(`
  <tr id="a11y-add-user-word-form-303-324"
    role="form" class="c-row  c-row--vocab-tools  c-table__form-row">
    <td>
      <div class="c-form-item  u-pad-rt-32">
        <input required=""
          type="text" aria-labelledby="a11y-foreign-word-label"
          class="c-form-item__input  js-word-form-input  u-width-full test-lesson-324-new-L2"
          lang="es">
      </div>
    </td>
    <td>
      <div class="c-form-item  u-pad-rt-32">
        <input required="" type="text" aria-labelledby="a11y-english-word-label"
          class="c-form-item__input  js-word-form-input  u-width-full test-lesson-324-new-L1">
      </div>
    </td>
  </tr>`);
document.body = htmlDOM.body;

beforeEach(() => {
  setAccentBarComponentMock();
});

describe('Add User Defined Word in Vocab Tools', () => {
  describe('when English vocab feature is disabled', () => {
    describe('when user defined word is not entered', () => {
      beforeEach(() => {
        wrapper = getWrapper(props);
      });

      it('registers the Accent Bar component to the input fields', () => {
        expect(VHL.AccentBarComponent.prototype.register).toHaveBeenCalled();
      });

      it('displays "target" input field as empty', () => {
        expect(
          wrapper.get(`.test-lesson-${props.lesson.id}-new-L2`).element.value
        ).toBe('');
      });

      it('displays "translation" input field as empty', () => {
        expect(
          wrapper.get(`.test-lesson-${props.lesson.id}-new-L1`).element.value
        ).toBe('');
      });

      it('shows "save" button as disabled', () => {
        expect(
          wrapper.get('.test-user-word-add-save').isVisible()
        ).toBeTruthy();
        expect(
          wrapper.get('.test-user-word-add-save').element
        ).toBeDisabled();
      });

      it('displays "cancel" button', () => {
        expect(
          wrapper.get('.test-user-word-add-cancel').isVisible()
        ).toBeTruthy();
      });
    });

    describe('User Defined word is entered', () => {
      beforeEach(async () => {
        wrapper = getWrapper(props);
        await wrapper.get(`.test-lesson-${props.lesson.id}-new-L2`).setValue('testTarget');
        await wrapper.get(`.test-lesson-${props.lesson.id}-new-L1`).setValue('testTranslation');
      });

      it('displays value in "target" input field', () => {
        expect(
          wrapper.get(`.test-lesson-${props.lesson.id}-new-L2`).element.value
        ).toBe('testTarget');
      });

      it('displays value in "translation" input field', () => {
        expect(
          wrapper.get(`.test-lesson-${props.lesson.id}-new-L1`).element.value
        ).toBe('testTranslation');
      });

      it('displays "save" button and enabled as well', () => {
        expect(
          wrapper.get('.test-user-word-add-save').isVisible()
        ).toBeTruthy();
        expect(
          wrapper.get('.test-user-word-add-save').element
        ).not.toBeDisabled();
      });

      it('displays "cancel" button', () => {
        expect(
          wrapper.get('.test-user-word-add-cancel').isVisible()
        ).toBeTruthy();
      });
    });

    describe('when cancel button is clicked', () => {
      beforeEach(async () => {
        wrapper = getWrapper(props);
        await wrapper.get('.test-user-word-add-cancel').trigger('click');
      });

      it('it deactivate Accent Bar component from input fields', () => {
        expect(VHL.AccentBarComponent.prototype.deactivateAll).toHaveBeenCalled();
      });
    });
  });

  describe('when English vocab feature is enabled', () => {
    describe('when user defined word is not entered', () => {
      beforeEach(() => {
        props.vocabHasDefinition = true;
        props.isTranslationHidden = true;
        wrapper = getWrapper(props);
      });

      it('displays "target" input field for English word', () => {
        expect(wrapper.find(`.test-lesson-${props.lesson.id}-new-L2`).exists()).toBeTruthy();
      });

      it('does not displays "translation" input field', () => {
        expect(wrapper.find(`.test-lesson-${props.lesson.id}-new-L1`).exists()).toBeFalsy();
      });

      it('displays "definition" input field for English word', () => {
        expect(
          wrapper.find(`.test-lesson-${props.lesson.id}-new-definition`).exists()
        ).toBeTruthy();
      });

      it('displays "save" button as disabled', () => {
        expect(
          wrapper.get('.test-user-word-add-save').isVisible()
        ).toBeTruthy();
        expect(
          wrapper.get('.test-user-word-add-save').element
        ).toBeDisabled();
      });

      it('displays "cancel" button as enabled', () => {
        expect(
          wrapper.get('.test-user-word-add-cancel').isVisible()
        ).toBeTruthy();
      });
    });

    describe('when English Word and its note is entered', () => {
      beforeEach(async () => {
        props.vocabHasDefinition = true;
        props.isTranslationHidden = true;
        wrapper = getWrapper(props);
        await wrapper.get(`.test-lesson-${props.lesson.id}-new-L2`).setValue('testTarget');
        await wrapper.get(`.test-lesson-${props.lesson.id}-new-definition`).setValue(
          'This is the note corresponding to the target word.'
        );
      });

      it('displays value in "target" input field', () => {
        expect(
          wrapper.get(`.test-lesson-${props.lesson.id}-new-L2`).element.value
        ).toBe('testTarget');
      });

      it('displays note value in "definition" input field', () => {
        expect(
          wrapper.get(`.test-lesson-${props.lesson.id}-new-definition`).element.value
        ).toBe('This is the note corresponding to the target word.');
      });

      it('displays "save" button and enabled as well', () => {
        expect(
          wrapper.get('.test-user-word-add-save').isVisible()
        ).toBeTruthy();
        expect(
          wrapper.get('.test-user-word-add-save').element
        ).not.toBeDisabled();
      });
    });
  });

  describe('accent bar', () => {
    describe('when accent bar is enabled for program', () => {
      it('instantiates an accent bar component', () => {
        wrapper = getWrapper(props);
        expect(VHL.AccentBarComponent.mock.instances.length).toBe(1);
      });
    });

    describe('when accent bar is disabled for program', () => {
      it('does not instantiate an accent bar component', () => {
        metaTagContent.mockReturnValueOnce('false');
        wrapper = getWrapper(props);
        expect(VHL.AccentBarComponent.mock.instances.length).toBe(0);
      });
    });
  });
});
