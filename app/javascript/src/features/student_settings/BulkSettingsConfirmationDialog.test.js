import { mount } from '@vue/test-utils';
import BulkSettingsConfirmationDialog from './BulkSettingsConfirmationDialog.vue';

describe('BulkSettingsConfirmationDialog', () => {
  let wrapper;
  const defaultProps = {
    selectedCount: 5,
    programLanguageName: 'Spanish',
    pendingSettings: {
      video_subtitle_languages: 'foreign'
    }
  };

  beforeEach(() => {
    wrapper = mount(BulkSettingsConfirmationDialog, {
      props: defaultProps
    });
  });

  describe('rendering', () => {
    it('renders the dialog with correct title', () => {
      expect(wrapper.find('.c-heading-v3--2').text()).toBe('Apply Settings');
    });

    it('renders both action buttons', () => {
      const cancelButton = wrapper.find('[data-testid="bulk-settings-cancel"]');
      const confirmButton = wrapper.find('[data-testid="bulk-settings-confirm"]');

      expect(cancelButton.exists()).toBe(true);
      expect(confirmButton.exists()).toBe(true);
      expect(cancelButton.text()).toBe('Cancel');
      expect(confirmButton.text()).toBe('Confirm');
    });

    it('applies correct button classes', () => {
      const cancelButton = wrapper.find('[data-testid="bulk-settings-cancel"]');
      const confirmButton = wrapper.find('[data-testid="bulk-settings-confirm"]');

      expect(cancelButton.classes()).toContain('c-button-v3--tertiary');
      expect(confirmButton.classes()).toContain('c-button-v3--primary');
    });
  });

  describe('events', () => {
    it('emits confirm event when confirm button is clicked', async () => {
      const confirmButton = wrapper.find('[data-testid="bulk-settings-confirm"]');
      await confirmButton.trigger('click');
      expect(wrapper.emitted('confirm')).toBeTruthy();
    });

    it('emits cancel event when cancel button is clicked', async () => {
      const cancelButton = wrapper.find('[data-testid="bulk-settings-cancel"]');
      await cancelButton.trigger('click');
      expect(wrapper.emitted('cancel')).toBeTruthy();
    });
  });

  describe('styling', () => {
    it('applies correct dialog width', () => {
      expect(wrapper.find('sl-dialog').attributes('style')).toContain('--width: 450px');
    });
  });

  describe('message generation', () => {
    describe('getKeyMessage', () => {
      it('returns correct message for video subtitles', () => {
        expect(wrapper.vm.getKeyMessage('video_subtitle_languages')).toBe('video subtitles and closed captions');
      });

      it('returns correct message for video transcripts', () => {
        expect(wrapper.vm.getKeyMessage('video_transcript_languages')).toBe('video transcripts');
      });

      it('returns correct message for audio transcripts', () => {
        expect(wrapper.vm.getKeyMessage('audio_transcript')).toBe('audio transcripts');
      });

      it('returns correct message for input mode', () => {
        expect(wrapper.vm.getKeyMessage('input_mode')).toBe('input mode');
      });
    });

    describe('getValueMessage', () => {
      describe('video subtitles and transcripts', () => {
        it('returns correct message for foreign language only', () => {
          expect(wrapper.vm.getValueMessage('Spanish', 'video_subtitle_languages', 'foreign'))
            .toBe('turn on Spanish');
        });

        it('returns correct message for foreign and English', () => {
          expect(wrapper.vm.getValueMessage('Spanish', 'video_subtitle_languages', 'foreign_and_english'))
            .toBe('turn on Spanish and English');
        });

        it('returns correct message for off', () => {
          expect(wrapper.vm.getValueMessage('Spanish', 'video_subtitle_languages', 'none'))
            .toBe('turn off');
        });
      });

      describe('audio transcripts', () => {
        it('returns correct message for turning on', () => {
          expect(wrapper.vm.getValueMessage('Spanish', 'audio_transcript', true))
            .toBe('turn on');
        });

        it('returns correct message for turning off', () => {
          expect(wrapper.vm.getValueMessage('Spanish', 'audio_transcript', false))
            .toBe('turn off');
        });
      });

      it('returns correct message for input_mode true', () => {
        expect(wrapper.vm.getValueMessage('Spanish', 'input_mode', true)).toBe('turn on');
      });
      it('returns correct message for input_mode false', () => {
        expect(wrapper.vm.getValueMessage('Spanish', 'input_mode', false)).toBe('turn off');
      });
    });

    describe('getDisplayValue', () => {
      it('returns program language for foreign', () => {
        expect(wrapper.vm.getDisplayValue('foreign', 'Spanish')).toBe('Spanish');
      });

      it('returns combined languages for foreign_and_english', () => {
        expect(wrapper.vm.getDisplayValue('foreign_and_english', 'Spanish')).toBe('Spanish and English');
      });

      it('returns off for none', () => {
        expect(wrapper.vm.getDisplayValue('none', 'Spanish')).toBe('off');
      });
    });

    describe('getStudentCountMessage', () => {
      it('returns singular form for one student', () => {
        expect(wrapper.vm.getStudentCountMessage(1)).toBe('1 student');
      });

      it('returns plural form for multiple students', () => {
        expect(wrapper.vm.getStudentCountMessage(5)).toBe('5 students');
      });
    });

    describe('confirmationMessage', () => {
      it('generates correct message for video subtitles', () => {
        wrapper = mount(BulkSettingsConfirmationDialog, {
          props: {
            selectedCount: 3,
            programLanguageName: 'Spanish',
            pendingSettings: {
              video_subtitle_languages: 'foreign'
            }
          }
        });
        expect(wrapper.vm.confirmationMessage).toBe('This action will turn on Spanish video subtitles and closed captions for 3 students.');
      });

      it('generates correct message for video transcripts', () => {
        wrapper = mount(BulkSettingsConfirmationDialog, {
          props: {
            selectedCount: 1,
            programLanguageName: 'French',
            pendingSettings: {
              video_transcript_languages: 'foreign_and_english'
            }
          }
        });
        expect(wrapper.vm.confirmationMessage).toBe('This action will turn on French and English video transcripts for 1 student.');
      });

      it('generates correct message for audio transcripts', () => {
        wrapper = mount(BulkSettingsConfirmationDialog, {
          props: {
            selectedCount: 2,
            programLanguageName: 'German',
            pendingSettings: {
              audio_transcript: true
            }
          }
        });
        expect(wrapper.vm.confirmationMessage).toBe('This action will turn on audio transcripts for 2 students.');
      });

      it('generates correct message for input_mode on', () => {
        wrapper = mount(BulkSettingsConfirmationDialog, {
          props: {
            selectedCount: 2,
            programLanguage: 'German',
            pendingSettings: {
              input_mode: true
            }
          }
        });
        expect(wrapper.vm.confirmationMessage).toBe('This action will turn on input mode for 2 students.');
      });
      it('generates correct message for input_mode off', () => {
        wrapper = mount(BulkSettingsConfirmationDialog, {
          props: {
            selectedCount: 1,
            programLanguage: 'German',
            pendingSettings: {
              input_mode: false
            }
          }
        });
        expect(wrapper.vm.confirmationMessage).toBe('This action will turn off input mode for 1 student.');
      });
    });
  });
});
