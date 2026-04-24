import { mount } from '@vue/test-utils';
import ActivityNote from 'features/instructor_notes/ActivityNote';
import * as ajaxUtils from 'shared/ajax_utils';
import fetchMock from 'fetch-mock';

const mockSetupAudioPlayback = jest.fn();

jest.mock(
  'shared/vue/use_recording_player_setup',
  () => {
    return jest.fn().mockImplementation(
      (refPlayerInstance, refPlaybackButton, localState) => {
        return {
          initPlayer: jest.fn(),
          onPlayBackActivate: jest.fn(),
          onPlayBackDeactivate: jest.fn(),
          resetPlayerMediaButton: jest.fn(),
          setupAudioPlayBack: mockSetupAudioPlayback,
        };
      }
    );
  }
);

VHL = {
  Music: { V1: {}},
  InstructorNotes: {},
};

VHL.InstructorNotes.Config = {
  cdnPrefix: 'cdnPrefix',
  endpoint: 'endpoint',
};

VHL.Music.V1.Disclosure = class Disclosure {
  constructor() {}
  toggle() {}
};


describe('ActivityNote', () => {
  let wrapper;

  const injections = {
    allowsExpandedNotes: true,
    controllerType: 'activities',
    userType: 'Instructor',
  };

  const note = {
    id: 1,
    title: 'Test note',
    body_text: 'Test Instructor Note',
    activity_id: 1,
    program_id: 1,
  };

  const options = { injections, props: { note }};

  function getWrapper(options) {
    return mount(ActivityNote, {
      global: {
        provide: options.injections,
        stubs: {
          MusicMediaButton: {
            template: '<div>media button</div>',
          },
          EditActivityNote: {
            template: '<div>edit modal</div>',
          },
        },
      },
      props: options.props,
    });
  }

  describe('I can see note basic information', () => {
    beforeEach(() => {
      wrapper = getWrapper(options);
    });

    it('I can see note title', () => {
      expect(wrapper.get('.test-intructor-note-title').text()).toBe(note.title);
    });

    it('I can see note body icon', () => {
      expect(wrapper.find('.test-instructor-note-icon').exists()).toBeTruthy();
    });

    it('I can see note body text', () => {
      expect(wrapper.get('.test-instructor-note-text').text()).toBe(
        note.body_text
      );
    });

    it('I can see disclosure icon', () => {
      expect(wrapper.find('.test-disclosure-marker').exists).toBeTruthy();
    });
  });

  describe('When recording is present', () => {
    beforeEach(() => {
      note.recording_path = 'http://recording-path.com';
      wrapper = getWrapper(options);
    });

    it('I can see audio icon on disclosure button', () => {
      expect(wrapper.find('.test-audio-note-icon').exists()).toBeTruthy();
    });

    it('I can see audio button on disclosure body', () => {
      expect(wrapper.find('.test-note-player').exists()).toBeTruthy;
    });
  });

  describe('When recording is not present', () => {
    beforeEach(() => {
      note.recording_path = null;
      wrapper = getWrapper(options);
    });

    it('I can not see audio icon on disclosure button', () => {
      expect(wrapper.find('.test-audio-note-icon').exists()).toBeFalsy;
    });

    it('I can not see audio button on disclosure body', () => {
      expect(wrapper.find('.test-note-player').exists()).toBeFalsy;
    });
  });

  describe('When logged in as instructor', () => {
    beforeEach(() => {
      injections.userType = 'Instructor';
      wrapper = getWrapper(options);
    });

    it('I can see edit and delete button container', () => {
      expect(wrapper.find('.test-instructor-note-action-link').exists()).toBeTruthy();
    });
  });

  describe('When logged in as student', () => {
    beforeEach(() => {
      injections.userType = 'Student';
      wrapper = getWrapper(options);
    });

    it('I can not see edit and delete button container', () => {
      wrapper = getWrapper(options);
      expect(wrapper.find('.test-instructor-note-action-link').exists()).toBeFalsy();
    });
  });

  describe('When expanded notes are allowed', () => {
    let toggle;

    beforeEach(() => {
      toggle = VHL.Music.V1.Disclosure.prototype.toggle = jest.fn();
      injections.allowsExpandedNotes = true;
    });

    describe('When note type is expanded', () => {
      it('"toggle" on VHL.Music.V1.Disclosure should be called', () => {
        note.note_type = 'expanded';
        wrapper = getWrapper(options);
        expect(toggle).toHaveBeenCalledTimes(1);
      });
    });

    describe('When note type is collapsed', () => {
      it('"toggle" on VHL.Music.V1.Disclosure should not be called', () => {
        note.note_type = 'collapsed';
        wrapper = getWrapper(options);
        expect(toggle).not.toHaveBeenCalled();
      });
    });
  });

  describe('When expanded notes are not allowed', () => {
    let toggle;

    beforeEach(() => {
      toggle = VHL.Music.V1.Disclosure.prototype.toggle = jest.fn();
      injections.allowsExpandedNotes = false;
    });

    describe('When note type is expanded', () => {
      it('"toggle" on VHL.Music.V1.Disclosure should not be called', () => {
        note.note_type = 'expanded';
        wrapper = getWrapper(options);
        expect(toggle).toHaveBeenCalledTimes(0);
      });
    });

    describe('When note type is collapsed', () => {
      it('"toggle" on VHL.Music.V1.Disclosure should not be called', () => {
        note.note_type = 'collapsed';
        wrapper = getWrapper(options);
        expect(toggle).toHaveBeenCalledTimes(0);
      });
    });
  });

  describe('when "Edit" clicked', () => {
    let editButton;
    beforeEach(() => {
      /* Edit button is only visible to instructor */
      injections.userType = 'Instructor';
      wrapper = getWrapper(options);
      editButton = wrapper.get('.test-edit-note');
    });

    it('edit dialog is not shown before', () => {
      expect(wrapper.find('.test-edit-modal').exists()).toBeFalsy();
    });

    it('edit dialog is shown on edit click', async () => {
      await editButton.trigger('click');
      expect(wrapper.find('.test-edit-modal').exists()).toBeTruthy();
    });
  });

  describe('when "Delete" clicked', () => {
    const deleteUrl =
      `/instructor/${note.program_id}/activity/${note.activity_id}/activity_notes/${note.id}`;

    beforeEach(() => {
      /* Delete button is only visible to instructor */
      injections.userType = 'Instructor';

      /* Mock the fetch call. */
      fetchMock.mock(deleteUrl, { status: 200, body: {}});
    });

    afterEach(() => {
      fetchMock.restore();
    });

    it('confirm dialog is shown', () => {
      window.confirm = jest.fn(() => false);
      wrapper = getWrapper(options);
      const deleteButton = wrapper.find('.test-delete-note');
      deleteButton.trigger('click');
      expect(window.confirm).toBeCalled();
    });

    it('delete api is called on confirm', async () => {
      window.confirm = jest.fn(() => true);
      const spy = spyOn(ajaxUtils, 'deleteFromEndpoint').and.callThrough();
      wrapper = getWrapper(options);
      const deleteButton = wrapper.find('.test-delete-note');
      deleteButton.trigger('click');
      expect(spy).toHaveBeenCalledWith(deleteUrl, jasmine.any(Function));
    });
  });
});
