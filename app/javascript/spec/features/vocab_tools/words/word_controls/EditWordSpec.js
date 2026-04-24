import { mount } from '@vue/test-utils';
import EditWord from 'features/vocab_tools/words/word_controls/EditWord';
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
  unit: {
    id: 303,
    in_course: true,
    name: 'Lección 1',
  },
  word: {
    id: 10,
    target: 'testTarget',
    topic: 'My Words',
    translation: 'testTranslation',
    definition: 'testDefinition',
  },
  targetLanguage: 'Spanish',
  vocabHasDefinition: false,
  index: 1,
};

const getWrapper = (propsData) => {
  return mount(EditWord, { props: propsData });
};

const htmlDOM = getHtmlDocument(`
<tr id="a11y-edit-user-word-1-form-303-324" class="c-row  c-row--vocab-tools">
  <td role="status">
    <div>
      <div class="test-target-word">testTarget</div>
      <div class="c-form-item test-form-item" style="display: none;">
        <input required="" type="text" aria-labelledby="a11y-foreign-word-label"
          class="c-form-item__input  js-word-form-input test-edit-10-L2">
      </div>
    </div>
  </td>
  <td>
    <div>
      <div class="test-translation-word">testTranslation</div>
      <div class="c-form-item test-form-item" style="display: none;">
        <input required="" type="text" aria-labelledby="a11y-foreign-word-label"
          class="c-form-item__input  js-word-form-input test-edit-10-L1">
      </div>
    </div>
  </td>
</tr>`);
document.body = htmlDOM.body;

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

beforeEach(() => {
  setAccentBarComponentMock();
});

describe('Vocab Tools Edit User Defined Word', () => {
  describe('when isTranslationHidden is false', () => {
    describe('Edit user word and its translation', () => {
      beforeEach(() => wrapper = getWrapper(props));

      it('returns "TR" html element as output', () => {
        expect(wrapper.element.tagName).toBe('TR');
      });

      it('displays edit icon', () => {
        expect(
          wrapper.get('.test-user-word-edit').find('svg').exists()
        ).toBeTruthy();
      });

      it('displays "target" text', () => {
        expect(
          wrapper.get('.test-target-word').text()
        ).toBe('testTarget');
      });

      it('displays "translation" text', () => {
        expect(
          wrapper.get('.test-translation-word').text()
        ).toBe('testTranslation');
      });

      it('does not display any form input item', () => {
        expect(
          wrapper.find('.test-form-item').exists()
        ).toBeFalsy();
      });

      it('does not display save button', () => {
        expect(
          wrapper.find('.test-user-word-edit-save').exists()
        ).toBeFalsy();
      });

      it('does not display delete button', () => {
        expect(
          wrapper.find('.test-user-word-delete').exists()
        ).toBeFalsy();
      });
    });

    describe('Clicks Edit word', () => {
      beforeEach(async () => {
        wrapper = getWrapper(props);
        await wrapper.get('.test-user-word-edit').trigger('click');
      });

      it('registers the Accent Bar component to the input fields', () => {
        expect(VHL.AccentBarComponent.prototype.register).toHaveBeenCalled();
      });

      it('does not display "target" text in non edit mode', () => {
        expect(
          wrapper.find('.test-target-word').exists()
        ).toBeFalsy();
      });

      it('does not display "translation" text in non edit mode', () => {
        expect(
          wrapper.find('.test-translation-word').exists()
        ).toBeFalsy();
      });

      it('displays "target" text in input field', () => {
        expect(
          wrapper.find(`.test-edit-${props.word.id}-L2`).element.value
        ).toBe('testTarget');
      });

      it('displays "translation" text in input field', () => {
        expect(
          wrapper.find(`.test-edit-${props.word.id}-L1`).element.value
        ).toBe('testTranslation');
      });

      it('shows "save" button as enabled', () => {
        expect(
          wrapper.find('.test-user-word-edit-save').exists()
        ).toBeTruthy();
        expect(
          wrapper.get('.test-user-word-edit-save').element
        ).not.toBeDisabled();
      });

      it('shows "delete" button as enabled', () => {
        expect(
          wrapper.find('.test-user-word-delete').exists()
        ).toBeTruthy();
        expect(
          wrapper.get('.test-user-word-delete').element
        ).not.toBeDisabled();
      });
    });

    describe('Clicks Delete word', () => {
      beforeEach(async () => {
        wrapper = getWrapper(props);
        await wrapper.get('.test-user-word-edit').trigger('click');
        await wrapper.get('.test-user-word-delete').trigger('click');
      });

      it('displays confirmation dialog box', () => {
        expect(
          wrapper.get('.dialog-panel').isVisible()
        ).toBeTruthy();
      });

      it(`displays "Do you want to delete ${props.word.target}?" over confirmation dialog box`, () => {
        expect(
          wrapper.get('.dialog-panel__body').get('#confirm-delete-modal-label').text()
        ).toBe(`Do you want to delete ${props.word.target}?`);
      });

      it('displays "Yes" button to confirm delete', () => {
        expect(
          wrapper.find('.dialog-panel__footer').get('.confirm-yes').exists()
        ).toBeTruthy();
      });

      it('displays "No" button to cancel delete', () => {
        expect(
          wrapper.find('.dialog-panel__footer').get('.confirm-no').exists()
        ).toBeTruthy();
      });
    });

    describe('When move out from edit mode', () => {
      beforeEach(async () => {
        wrapper = getWrapper(props);
        await wrapper.get('.test-user-word-edit').trigger('click');
        await wrapper.get('.test-user-word-delete').trigger('click');
        await wrapper.get('.test-confirm-no').trigger('click');
      });

      it('it deactivate Accent Bar component from input fields', () => {
        expect(VHL.AccentBarComponent.prototype.deactivateAll).toHaveBeenCalled();
      });

      it('does not display save button', () => {
        expect(
          wrapper.find('.test-user-word-edit-save').exists()
        ).toBeFalsy();
      });

      it('does not display delete button', () => {
        expect(
          wrapper.find('.test-user-word-delete').exists()
        ).toBeFalsy();
      });
    });
  });

  describe('when isTranslationHidden is true', () => {
    describe('when edit english vocab user defined word', () => {
      beforeEach(() => {
        const propsData = { ...props, isTranslationHidden: true, vocabHasDefinition: true };
        wrapper = getWrapper(propsData);
      });

      it('displays edit icon', () => {
        expect(
          wrapper.get('.test-user-word-edit').find('svg').exists()
        ).toBeTruthy();
      });

      it('displays "target" text', () => {
        expect(
          wrapper.get('.test-target-word').text()
        ).toBe('testTarget');
      });

      it('does not display "translation" text', () => {
        expect(wrapper.find('.test-translation-word').exists()).toBeFalsy();
      });

      it('displays "definition" text', () => {
        expect(wrapper.find('.test-definition-word').text()).toBe('testDefinition');
      });

      it('does not display save button', () => {
        expect(
          wrapper.find('.test-user-word-edit-save').exists()
        ).toBeFalsy();
      });

      it('does not display delete button', () => {
        expect(
          wrapper.find('.test-user-word-delete').exists()
        ).toBeFalsy();
      });
    });

    describe('when clicks Edit word in english vocab tools', () => {
      beforeEach(async () => {
        const propsData = { ...props, isTranslationHidden: true, vocabHasDefinition: true };
        wrapper = getWrapper(propsData);
        await wrapper.get('.test-user-word-edit').trigger('click');
      });

      it('registers the Accent Bar component to the input fields', () => {
        expect(VHL.AccentBarComponent.prototype.register).toHaveBeenCalled();
      });

      it('does not display "target" text in non edit mode', () => {
        expect(
          wrapper.find('.test-target-word').exists()
        ).toBeFalsy();
      });

      it('does not display "definition" text in non edit mode', () => {
        expect(
          wrapper.find('.test-definition-word').exists()
        ).toBeFalsy();
      });

      it('displays "target" text in input field', () => {
        expect(
          wrapper.find(`.test-edit-${props.word.id}-L2`).element.value
        ).toBe('testTarget');
      });

      it('does not display "translation" input field', () => {
        expect(wrapper.find(`.test-edit-${props.word.id}-L1`).exists()).toBeFalsy();
      });

      it('displays "definition" text in input field', () => {
        expect(
          wrapper.find(`.test-edit-${props.word.id}-definition`).element.value
        ).toBe('testDefinition');
      });

      it('shows "save" button as enabled', () => {
        expect(
          wrapper.find('.test-user-word-edit-save').exists()
        ).toBeTruthy();
        expect(
          wrapper.get('.test-user-word-edit-save').element
        ).not.toBeDisabled();
      });

      it('shows "delete" button as enabled', () => {
        expect(
          wrapper.find('.test-user-word-delete').exists()
        ).toBeTruthy();
        expect(
          wrapper.get('.test-user-word-delete').element
        ).not.toBeDisabled();
      });
    });

    describe('when clicks Delete word in vocab tools', () => {
      beforeEach(async () => {
        wrapper = getWrapper(props);
        await wrapper.get('.test-user-word-edit').trigger('click');
        await wrapper.get('.test-user-word-delete').trigger('click');
      });

      it('displays confirmation dialog box', () => {
        expect(
          wrapper.get('.dialog-panel').isVisible()
        ).toBeTruthy();
      });

      it(`displays "Do you want to delete ${props.word.target}?" over confirmation dialog box`, () => {
        expect(
          wrapper.get('.dialog-panel__body').get('#confirm-delete-modal-label').text()
        ).toBe(`Do you want to delete ${props.word.target}?`);
      });

      it('displays "Yes" button to confirm delete', () => {
        expect(
          wrapper.find('.dialog-panel__footer').get('.confirm-yes').exists()
        ).toBeTruthy();
      });

      it('displays "No" button to cancel delete', () => {
        expect(
          wrapper.find('.dialog-panel__footer').get('.confirm-no').exists()
        ).toBeTruthy();
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
