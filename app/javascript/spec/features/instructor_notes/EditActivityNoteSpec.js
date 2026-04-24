import { mount } from '@vue/test-utils';
import EditActivityNote from 'features/instructor_notes/EditActivityNote';
import * as ajaxUtils from 'shared/ajax_utils';
import fetchMock from 'fetch-mock';

CKEDITOR = {
  env: {},
  replace() {},
};

VHL = VHL || {};
VHL.AccentBarComponent = class {
  constructor() {}
  register() {
    jest.fn();
  }
  deactivateAll() {
    jest.fn();
  }
};

const programMeta = document.createElement('meta');
programMeta.setAttribute('name', 'VHL.program_language');
programMeta.setAttribute('content', 'es');

document.head.append(programMeta);

describe('EditActivityNote', () => {
  let wrapper;

  const note = {
    id: 1,
    title: 'Test title',
    body_text: 'Test description',
    note_item_id: 1,
    note_type: 'expanded',
    activity_id: 1,
    program_id: 1,
  };

  const noteUrl = '/instructor/1/activity/1/activity_notes/1';

  const setValue = async (selector, value) => {
    const inputElm = wrapper.get(selector);
    await inputElm.setValue(value);
  };

  const options = {
    injections: { allowsExpandedNotes: true },
    props: { note },
  };

  function getWrapper() {
    return mount(EditActivityNote, {
      props: options.props,
      global: {
        provide: options.injections,
        stubs: {
          InstructorNoteAudioControls: {
            template: '<div></div>',
          },
        },
      },
    });
  }

  describe('when mounted.', () => {
    beforeEach(() => {
      wrapper = getWrapper(options);
    });

    it('I can see title "Edit Instructor Note', () => {
      expect(wrapper.get('.test-modal-heading').text()).toBe('Edit Instructor Note');
    });

    it('I can see close button on dialog', () => {
      expect(wrapper.find('.test-modal-close-button').exists()).toBeTruthy();
    });

    it('I can see populated title text field', () => {
      expect(wrapper.get('.test-note-title-input').element.value).toBe('Test title');
    });

    it('I can see populated note body text area', () => {
      expect(wrapper.get('.test-note-body-text').element.value).toBe('Test description');
    });

    it('I can see disabled submit button', () => {
      expect(wrapper.get('.test-submit-button').element).not.toBeDisabled();
    });
  });


  describe('when expanded notes are allowed.', () => {
    beforeEach(() => {
      options.injections.allowsExpandedNotes = true;
      wrapper = getWrapper(options);
    });

    it('I can see "expanded" note_type selected"', () => {
      expect(wrapper.get('input[name=note_type]').element.value).toBe(note.note_type);
    });
  });

  describe('when expanded notes are not allowed.', () => {
    beforeEach(() => {
      options.injections.allowsExpandedNotes = false;
      wrapper = getWrapper(options);
    });

    it('I can not see note_type container', () => {
      expect(wrapper.find('.test-note-type').exists()).toBeFalsy();
    });
  });

  describe('when note title and body_text are changed.', () => {
    beforeEach(() => {
      wrapper = getWrapper(options);
    });

    it('I can see disable submit button if title and body_text are not present', async () => {
      await setValue('.test-note-title-input', '');
      await setValue('.test-note-body-text', '');
      expect(wrapper.get('.test-submit-button').element).toBeDisabled();
    });

    it('I can see enabled submit button if title is present', async () => {
      await setValue('.test-note-title-input', 'Test title');
      await setValue('.test-note-body-text', '');
      expect(wrapper.get('.test-submit-button').element).not.toBeDisabled();
    });

    it('I can see enabled submit button if body_text is present', async () => {
      await setValue('.test-note-title-input', '');
      await setValue('.test-note-body-text', 'Test description');
      expect(wrapper.get('.test-submit-button').element).not.toBeDisabled();
    });
  });

  describe('when cancel clicked.', () => {
    beforeEach(() => {
      wrapper = getWrapper(options);
    });

    it('emits "close" event', async () => {
      await wrapper.find('.test-cancel-button').trigger('click');
      expect(wrapper.emitted().close).toBeTruthy();
    });
  });

  describe('when submit clicked.', () => {
    beforeEach(async () => {
      fetchMock.mock({
        url: noteUrl, response: { status: 200, body: {}}});
      wrapper = getWrapper(options);
      spyOn(ajaxUtils, 'putToEndpoint').and.callThrough();
    });

    afterEach(() => {
      fetchMock.restore();
    });

    it('does make an ajax request', async () => {
      await wrapper.find('.test-submit-button').trigger('click');
      expect(ajaxUtils.putToEndpoint).toHaveBeenCalledWith(
        noteUrl,
        jasmine.any(Object),
        jasmine.any(Function)
      );
    });
  });
});
