import { mount } from '@vue/test-utils';
import AddActivityNote from 'features/instructor_notes/AddActivityNote';
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

describe('AddActivityNote', () => {
  let wrapper;

  const props = {
    allowsExpandedNotes: true,
    activityId: 1,
    programId: 1,
  };

  const noteUrl = '/instructor/1/activity/1/activity_notes';

  const setValue = async (selector, value) => {
    const inputElm = wrapper.get(selector);
    await inputElm.setValue(value);
  };

  function getWrapper() {
    const wrapper = mount(AddActivityNote, {
      props,
      global: {
        stubs: {
          InstructorNoteAudioControls: {
            template: '<div></div>',
          },
        },
      },
    });
    wrapper.vm.showDialog();
    return wrapper;
  }

  describe('when showDialog is called.', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('I can see title "Add Instructor Note', () => {
      expect(wrapper.get('.test-modal-heading').text()).toBe('Add Instructor Note');
    });

    it('I can see close button on dialog', () => {
      expect(wrapper.get('.test-modal-close-button').exists()).toBeTruthy();
    });

    it('I can see empty title text field', () => {
      expect(wrapper.get('.test-note-title-input').element.value).toBe('');
    });

    it('I can see empty note body text area', () => {
      expect(wrapper.get('.test-note-body-text').element.value).toBe('');
    });

    it('I can see disabled submit button', () => {
      expect(wrapper.get('.test-submit-button').element).toBeDisabled();
    });
  });


  describe('when expanded notes are allowed.', () => {
    beforeEach(() => {
      props.allowsExpandedNotes = true;
      wrapper = getWrapper();
    });

    it('I can see "expanded" note_type selected"', () => {
      expect(wrapper.get('input[name=note_type]').element.value).toBe('expanded');
    });
  });

  describe('when expanded notes are not allowed.', () => {
    beforeEach(() => {
      props.allowsExpandedNotes = false;
      wrapper = getWrapper();
    });

    it('note_type value is set to "collapsed"', () => {
      expect(wrapper.vm.currentNote.note_type).toBe('collapsed');
    });

    it('I can not see note_type container', () => {
      expect(wrapper.find('.test-note-type').exists()).toBeFalsy();
    });
  });

  describe('when note title and body_text are changed.', () => {
    beforeEach(() => {
      wrapper = getWrapper();
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
      wrapper = getWrapper();
    });

    it('I can not see modal with title "Add Instructor Note', async () => {
      await wrapper.find('.test-cancel-button').trigger('click');
      expect(wrapper.find('.test-modal-heading').exists()).toBeFalsy();
    });
  });

  describe('when submit clicked.', () => {
    beforeEach(async () => {
      fetchMock.mock({
        url: noteUrl, response: { status: 200, body: {}}});
      wrapper = getWrapper();
      wrapper.vm.showDialog();
      spyOn(ajaxUtils, 'postToEndpoint').and.callThrough();
    });

    afterEach(() => {
      fetchMock.restore();
    });

    it('does make an ajax request', async () => {
      await setValue('.test-note-title-input', 'Test title');
      await wrapper.get('.test-submit-button').trigger('click');
      expect(ajaxUtils.postToEndpoint).toHaveBeenCalledWith(
        noteUrl,
        jasmine.any(Object),
        jasmine.any(Function)
      );
    });
  });
});
